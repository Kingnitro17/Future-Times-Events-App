import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/ticket_repository.dart';
import '../../../shared/models/models.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/ft_widgets.dart';
import '../../../core/config/app_config.dart';

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, required this.ticketId});
  final String ticketId;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _repo = TicketRepository();
  Ticket? _ticket;
  String? _rawToken;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ticket = await _repo.getTicketById(widget.ticketId);
      if (ticket == null) {
        setState(() { _error = 'Ticket not found.'; _loading = false; });
        return;
      }
      // Load raw token from secure storage (may be null if from another device)
      final rawToken = await _repo.getRawToken(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticket = ticket;
          _rawToken = rawToken;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _copyTicketNumber() {
    if (_ticket == null) return;
    Clipboard.setData(ClipboardData(text: _ticket!.ticketNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ticket number copied.')),
    );
  }

  void _shareTicket() {
    if (_ticket == null) return;
    final eventUrl =
        '${AppConfig.appBaseUrl}/events/${_ticket!.eventId}';
    SharePlus.share(ShareParams(
      text:
          'My ticket for ${_ticket!.eventTitle ?? "an event"} – $eventUrl',
      subject: 'My Future Times ticket',
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: FtErrorState(message: _error!, onRetry: _load),
      );
    }

    final ticket = _ticket!;
    final isValid = ticket.isValid;
    final gradient = isValid ? AppGradients.primary : AppGradients.ocean;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text(
          ticket.eventTitle ?? 'Ticket',
          style: AppTypography.h4.copyWith(color: AppColors.text),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareTicket,
            tooltip: 'Share ticket',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // ── Ticket card with QR ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violet.withAlpha(20),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Gradient header
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(gradient: gradient),
                    child: Column(
                      children: [
                        Text(
                          ticket.eventTitle ?? 'Event',
                          style: AppTypography.h3.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (ticket.eventStartsAt != null)
                          Text(
                            DateFormat('EEEE, d MMMM y · h:mm a')
                                .format(ticket.eventStartsAt!),
                            style: AppTypography.caption.copyWith(
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        if (ticket.eventVenueName != null)
                          Text(
                            ticket.eventVenueName!,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),

                  // Dashed divider
                  const _DashedDivider(),

                  // QR code
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: _QrSection(
                      ticket: ticket,
                      rawToken: _rawToken,
                    ),
                  ),

                  // Ticket details
                  const _DashedDivider(),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _TicketDetails(
                      ticket: ticket,
                      onCopy: _copyTicketNumber,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Attendee info ────────────────────────────────────────────────
            FtCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attendee', style: AppTypography.overline),
                  const SizedBox(height: AppSpacing.sm),
                  Text(ticket.attendeeName, style: AppTypography.bodyMedium),
                  Text(ticket.attendeeEmail, style: AppTypography.caption),
                  if (ticket.attendeePhone != null)
                    Text(ticket.attendeePhone!, style: AppTypography.caption),
                ],
              ),
            ),

            if (ticket.status != TicketStatus.issued) ...[
              const SizedBox(height: AppSpacing.md),
              FtCard(
                child: Row(
                  children: [
                    Icon(
                      ticket.isUsed
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: ticket.isUsed
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.isUsed
                                ? 'Checked In'
                                : ticket.status.label,
                            style: AppTypography.bodyMedium,
                          ),
                          if (ticket.checkedInAt != null)
                            Text(
                              DateFormat('d MMM y · h:mm a')
                                  .format(ticket.checkedInAt!),
                              style: AppTypography.caption,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ── QR Section ────────────────────────────────────────────────────────────────

class _QrSection extends StatelessWidget {
  const _QrSection({required this.ticket, required this.rawToken});
  final Ticket ticket;
  final String? rawToken;

  @override
  Widget build(BuildContext context) {
    if (!ticket.isValid) {
      return Column(
        children: [
          Icon(
            ticket.isUsed
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            size: 80,
            color: ticket.isUsed ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            ticket.isUsed ? 'Ticket has been used' : ticket.status.label,
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (rawToken == null) {
      return Column(
        children: [
          const Icon(Icons.qr_code_rounded,
              size: 80, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            'QR code available on the device used to purchase this ticket.',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // SECURITY: Display the raw token as a QR code.
    // The raw token is NEVER logged — only displayed here.
    return Semantics(
      label: 'QR code for ticket ${ticket.ticketNumber}. '
          'Show this at the event entrance.',
      image: true,
      child: QrImageView(
        data: rawToken!,
        version: QrVersions.auto,
        size: 220,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: AppColors.text,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: AppColors.text,
        ),
        backgroundColor: Colors.white,
      ),
    );
  }
}

// ── Ticket Info Details ───────────────────────────────────────────────────────

class _TicketDetails extends StatelessWidget {
  const _TicketDetails({required this.ticket, required this.onCopy});
  final Ticket ticket;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DetailRow(
          label: 'Ticket',
          value: ticket.ticketTypeName ?? 'Standard',
        ),
        const SizedBox(height: AppSpacing.sm),
        _DetailRow(
          label: 'Ticket #',
          value: ticket.ticketNumber,
          onTap: onCopy,
          trailing: const Icon(Icons.copy_rounded,
              size: 14, color: AppColors.textMuted),
        ),
        if (ticket.gate != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(label: 'Gate', value: ticket.gate!),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption),
          Row(
            children: [
              Text(value, style: AppTypography.bodyMedium),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(MediaQuery.sizeOf(context).width, 1),
      painter: _DashPainter(),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 8.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
