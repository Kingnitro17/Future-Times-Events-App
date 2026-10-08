import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/organizer_repository.dart';
import '../../../data/repositories/ticket_repository.dart';
import '../../../services/roles/role_service.dart';

class ScanTicketScreen extends StatefulWidget {
  const ScanTicketScreen({
    super.key,
    required this.authRepository,
    required this.organizerRepository,
    required this.ticketRepository,
    this.initialEventId,
  });

  final AuthRepository authRepository;
  final OrganizerRepository organizerRepository;
  final TicketRepository ticketRepository;
  final String? initialEventId;

  @override
  State<ScanTicketScreen> createState() => _ScanTicketScreenState();
}

class _ScanTicketScreenState extends State<ScanTicketScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _scannerController;
  final Map<String, DateTime> _recentScans = {};
  late Future<List<Map<String, dynamic>>> _eventsFuture;
  String? _selectedEventId;
  String? _resultTitle;
  String? _resultMessage;
  String? _resultAttendee;
  String? _resultTicketType;
  String? _resultTicketNumber;
  String? _resultCheckedInAt;
  Color _resultColor = AppColors.error;
  IconData _resultIcon = Icons.close_rounded;
  Timer? _resultTimer;
  bool _processing = false;
  int _checkedInCount = 0;
  bool _checkingRole = true;
  bool _cameraPermissionGranted = false;
  bool _cameraPermissionPermanentlyDenied = false;
  bool _checkingCameraPermission = true;
  String? _cameraErrorMessage;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    WidgetsBinding.instance.addObserver(this);
    _selectedEventId = widget.initialEventId;
    _eventsFuture = widget.organizerRepository.getMyEvents();
    _verifyRole();
    _checkCameraPermission(requestIfNeeded: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkCameraPermission();
  }

  Future<void> _checkCameraPermission({bool requestIfNeeded = false}) async {
    try {
      var status = await permissions.Permission.camera.status;
      if (!status.isGranted && requestIfNeeded && status.isDenied) {
        status = await permissions.Permission.camera.request();
      }
      if (!mounted) return;
      setState(() {
        _cameraPermissionGranted = status.isGranted;
        _cameraPermissionPermanentlyDenied =
            status.isPermanentlyDenied || status.isRestricted;
        _checkingCameraPermission = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _checkingCameraPermission = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not check camera access: $error')),
      );
    }
  }

  Future<void> _openCameraSettings() async {
    final opened = await permissions.openAppSettings();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open device settings.')),
      );
    }
  }

  Future<void> _verifyRole() async {
    final user = widget.authRepository.user;
    if (user == null) {
      if (mounted) {
        setState(() {
          _checkingRole = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/profile');
        });
      }
      return;
    }
    final role = await RoleService.instance.getRole(user.id);
    final ok = role == 'organizer' || role == 'super_admin';
    if (mounted) {
      setState(() => _checkingRole = false);
      if (!ok) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/profile');
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resultTimer?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_processing || _resultTitle != null) return;
    final payload = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .firstOrNull;
    if (payload == null) return;

    final now = DateTime.now();
    final previous = _recentScans[payload];
    if (previous != null &&
        now.difference(previous) < const Duration(seconds: 3)) {
      return;
    }
    _recentScans[payload] = now;
    _recentScans.removeWhere((_, timestamp) =>
        now.difference(timestamp) > const Duration(seconds: 3));

    setState(() => _processing = true);
    try {
      await _scannerController.stop();
      final result = await widget.ticketRepository.validateAndCheckInTicket(
        qrPayload: payload,
        gate: 'Main Gate',
        eventId: _selectedEventId,
      );
      if (!mounted) return;
      _showResult(result);
    } catch (_) {
      if (!mounted) return;
      await _showValidationError();
    }
  }

  void _showResult(Map<String, dynamic> result) {
    final valid = result['valid'] == true;
    final alreadyCheckedIn = result['already_checked_in'] == true;
    setState(() {
      _processing = false;
      _resultTitle = alreadyCheckedIn
          ? 'Already checked in'
          : (valid ? 'Valid ticket' : 'Invalid ticket');
      _resultMessage =
          result['message']?.toString() ?? 'Ticket could not be validated.';
      _resultAttendee = result['attendee_name']?.toString();
      _resultTicketType = result['ticket_type_name']?.toString() ??
          result['ticket_type']?.toString();
      _resultTicketNumber = result['ticket_number']?.toString();
      _resultCheckedInAt = result['checked_in_at']?.toString();
      _resultColor = alreadyCheckedIn
          ? Colors.amber.shade800
          : (valid ? AppColors.success : AppColors.error);
      _resultIcon = alreadyCheckedIn
          ? Icons.warning_amber_rounded
          : (valid ? Icons.check_circle_rounded : Icons.cancel_rounded);
      if (valid) _checkedInCount++;
    });
    if (valid || alreadyCheckedIn) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    _resultTimer = Timer(const Duration(milliseconds: 2500), _resumeScanning);
  }

  Future<void> _resumeScanning() async {
    if (!mounted) return;
    _resultTimer?.cancel();
    setState(() {
      _resultTitle = null;
      _resultMessage = null;
      _resultAttendee = null;
      _resultTicketType = null;
      _resultTicketNumber = null;
      _resultCheckedInAt = null;
    });
    try {
      await _scannerController.start();
    } on MobileScannerException catch (error) {
      if (mounted) _showCameraError(error);
    }
  }

  Future<void> _retryCamera() async {
    if (mounted) {
      setState(() => _cameraErrorMessage = null);
    }
    try {
      await _scannerController.start();
    } on MobileScannerException catch (error) {
      if (mounted) _showCameraError(error);
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _scannerController.switchCamera();
      if (mounted) setState(() => _cameraErrorMessage = null);
    } on MobileScannerException catch (error) {
      if (mounted) _showCameraError(error);
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
    } on MobileScannerException catch (error) {
      if (mounted) _showCameraError(error);
    }
  }

  void _showCameraError(MobileScannerException error) {
    setState(() {
      _cameraErrorMessage = error.errorDetails?.message ??
          'Camera unavailable (${error.errorCode.name}). Check camera access and try again.';
    });
  }

  Widget _cameraErrorOverlay(String message) => ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.no_photography_outlined,
                  color: Colors.white,
                  size: 52,
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _retryCamera,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Restart camera'),
                ),
                OutlinedButton(
                  onPressed: _openCameraSettings,
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _manualEntry() async {
    final controller = TextEditingController();
    final payload = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual entry'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Ticket number or QR payload',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Validate')),
        ],
      ),
    );
    controller.dispose();
    if (payload != null && payload.trim().isNotEmpty) {
      await _handleManualPayload(payload);
    }
  }

  Future<void> _handleManualPayload(String payload) async {
    if (_processing || _resultTitle != null) return;
    setState(() => _processing = true);
    try {
      await _scannerController.stop();
      final result = await widget.ticketRepository.validateAndCheckInTicket(
        qrPayload: payload,
        gate: 'Main Gate',
        eventId: _selectedEventId,
      );
      if (mounted) _showResult(result);
    } catch (_) {
      await _showValidationError();
    }
  }

  Future<void> _showValidationError() async {
    if (!mounted) return;
    setState(() => _processing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Could not validate ticket. Check your connection and try again.'),
      ),
    );
    if (_cameraPermissionGranted) {
      try {
        await _scannerController.start();
      } on MobileScannerException catch (error) {
        if (mounted) _showCameraError(error);
      }
    }
  }

  Widget _cameraAccessState() {
    if (_checkingCameraPermission) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined,
                  color: Colors.white, size: 52),
              const SizedBox(height: 14),
              const Text(
                'Camera access is required to scan tickets',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              if (!_cameraPermissionPermanentlyDenied)
                FilledButton.icon(
                  onPressed: () =>
                      _checkCameraPermission(requestIfNeeded: true),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Allow camera access'),
                ),
              OutlinedButton.icon(
                onPressed: _openCameraSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Open Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while we verify the role asynchronously
    if (_checkingRole) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_cameraPermissionGranted)
            MobileScanner(
              controller: _scannerController,
              onDetect: _handleBarcode,
              errorBuilder: (context, error) => ColoredBox(
                color: Colors.black,
                child: _cameraErrorOverlay(
                  _cameraErrorMessage ??
                      error.errorDetails?.message ??
                      'Camera unavailable (${error.errorCode.name}). Check camera access and try again.',
                ),
              ),
            )
          else
            _cameraAccessState(),
          if (_cameraErrorMessage != null && _cameraPermissionGranted)
            Positioned.fill(
              child: _cameraErrorOverlay(_cameraErrorMessage!),
            ),
          IgnorePointer(
            child: CustomPaint(painter: _ScannerOverlayPainter()),
          ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      color: Colors.white,
                      icon: const Icon(Icons.close_rounded),
                    ),
                    Expanded(child: _eventSelector()),
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _scannerController,
                      builder: (context, state, _) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((state.availableCameras ?? 0) > 1)
                            IconButton(
                              tooltip: 'Flip camera',
                              onPressed: _processing ? null : _switchCamera,
                              color: Colors.white,
                              icon: const Icon(Icons.cameraswitch_rounded),
                            ),
                          IconButton(
                            tooltip: state.torchState == TorchState.on
                                ? 'Turn torch off'
                                : 'Turn torch on',
                            onPressed: _processing ||
                                    state.torchState == TorchState.unavailable
                                ? null
                                : _toggleTorch,
                            color: Colors.white,
                            icon: Icon(state.torchState == TorchState.on
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_processing)
                  const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 20),
                Text('Checked in: $_checkedInCount',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: OutlinedButton.icon(
                    onPressed: _processing || _resultTitle != null
                        ? null
                        : _manualEntry,
                    icon: const Icon(Icons.keyboard_alt_outlined),
                    label: const Text('Manual entry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_resultTitle != null) _resultOverlay(),
        ],
      ),
    );
  }

  Widget _eventSelector() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <Map<String, dynamic>>[];
        final selectedExists =
            events.any((event) => event['id']?.toString() == _selectedEventId);
        return DropdownButton<String?>(
          value: selectedExists ? _selectedEventId : null,
          isExpanded: true,
          dropdownColor: Colors.black87,
          underline: const SizedBox.shrink(),
          style: const TextStyle(color: Colors.white),
          hint: const Text('All my events',
              style: TextStyle(color: Colors.white)),
          items: [
            const DropdownMenuItem<String?>(
                value: null, child: Text('All my events')),
            ...events.map((event) => DropdownMenuItem<String?>(
                  value: event['id']?.toString(),
                  child: Text(event['title']?.toString() ?? 'Untitled event',
                      overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: (value) => setState(() => _selectedEventId = value),
        );
      },
    );
  }

  Widget _resultOverlay() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(28),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_resultIcon, color: _resultColor, size: 64),
              const SizedBox(height: 12),
              Text(_resultTitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _resultColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (_resultAttendee != null) Text(_resultAttendee!),
              if (_resultTicketType != null) Text(_resultTicketType!),
              if (_resultTicketNumber != null) Text(_resultTicketNumber!),
              if (_resultCheckedInAt != null &&
                  _resultTitle == 'Already checked in')
                Text(_resultCheckedInAt!),
              const SizedBox(height: 8),
              Text(_resultMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _resumeScanning,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan next ticket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final frameSize = size.shortestSide * .68;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * .43),
      width: frameSize,
      height: frameSize,
    );
    final overlay = Path()..addRect(Offset.zero & size);
    final cutout = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, overlay, cutout),
      Paint()..color = Colors.black.withValues(alpha: .58),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
