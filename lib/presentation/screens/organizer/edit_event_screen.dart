import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/ft_service.dart';
import '../../../data/models/ft_service_booking.dart';
import '../../../data/repositories/ft_services_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/organizer_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../widgets/common/glass_app_bar.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/glass_container.dart';
import '../../widgets/common/premium_button.dart';
import '../../widgets/common/premium_card.dart';
import '../../widgets/common/premium_text_field.dart';
import '../ft_services/ft_service_detail_screen.dart';

class EditEventScreen extends StatefulWidget {
  const EditEventScreen({
    super.key,
    required this.authRepository,
    required this.organizerRepository,
    required this.paymentRepository,
    this.eventId,
  });

  final AuthRepository authRepository;
  final OrganizerRepository organizerRepository;
  final PaymentRepository paymentRepository;
  final String? eventId;

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _venueName = TextEditingController();
  final _venueAddress = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _picker = ImagePicker();
  final _tickets = <_TicketDraft>[_TicketDraft()];
  final _partners = <_PartnerDraft>[];
  final _ftServicesRepository = FtServicesRepository();
  List<FtService> _ftServices = const [];
  List<FtServiceBooking> _serviceBookings = const [];
  bool _loadingServices = false;
  bool _partnersChanged = false;
  bool _partnersAvailable = true;
  DateTime? _startsAt;
  DateTime? _endsAt;
  String? _category;
  String? _coverUrl;
  String? _status;
  String? _rejectionReason;
  bool _loading = false;
  bool _saving = false;
  bool _uploadingCover = false;
  bool _submittingForReview = false;
  String? _error;

  static const _categories = [
    'Music',
    'Concerts',
    'Sports',
    'Comedy',
    'Festivals',
    'Nightlife',
    'Business',
    'Culture',
    'Community',
    'Family',
  ];

  bool get _isLocked =>
      _status == 'published' || _status == 'live' || _status == 'ended';

  bool get _isFormValid {
    if (_title.text.trim().isEmpty ||
        _description.text.trim().isEmpty ||
        _venueName.text.trim().isEmpty ||
        _venueAddress.text.trim().isEmpty ||
        _category?.trim().isNotEmpty != true ||
        _startsAt == null ||
        _endsAt == null ||
        !_endsAt!.isAfter(_startsAt!)) {
      return false;
    }
    if (_tickets.any((ticket) =>
        ticket.name.text.trim().isEmpty ||
        num.tryParse(ticket.price.text.trim()) == null ||
        int.tryParse(ticket.quantity.text.trim()) == null)) {
      return false;
    }
    return _partners.every((partner) {
      if (partner.name.text.trim().isEmpty) return false;
      final website = partner.website.text.trim();
      if (website.isEmpty) return true;
      final uri = Uri.tryParse(website);
      return uri != null && uri.hasScheme && uri.host.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      _loadEvent();
    } else {
      _loadFtServices();
    }
  }

  Future<void> _loadFtServices() async {
    if (mounted) setState(() => _loadingServices = true);
    try {
      final services = await _ftServicesRepository.listServices();
      if (mounted) setState(() => _ftServices = services);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not load Future Times services: $error');
      }
    } finally {
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  Future<void> _loadEvent() async {
    setState(() => _loading = true);
    try {
      final event =
          await widget.organizerRepository.getEventForEdit(widget.eventId!);
      if (event == null) {
        throw StateError('Event not found or not owned by you.');
      }
      final types =
          await widget.organizerRepository.getTicketTypes(widget.eventId!);
      await _loadFtServices();
      List<Map<String, dynamic>> partners = const [];
      List<FtServiceBooking> bookings = const [];
      try {
        partners =
            await widget.organizerRepository.getEventPartners(widget.eventId!);
      } catch (error) {
        _partnersAvailable = false;
        _error = 'Partner editing is unavailable until the event-partners '
            'database migration is applied: $error';
      }
      try {
        bookings = await _ftServicesRepository.myBookings();
      } catch (error) {
        _error = 'Service bookings are unavailable: $error';
      }
      _title.text = event['title']?.toString() ?? '';
      _description.text = event['description']?.toString() ?? '';
      _venueName.text =
          event['venue_name']?.toString() ?? event['venue']?.toString() ?? '';
      _venueAddress.text = event['address']?.toString() ?? '';
      _latitude.text = (event['lat'] ?? event['latitude'])?.toString() ?? '';
      _longitude.text = (event['lng'] ?? event['longitude'])?.toString() ?? '';
      _category = event['category']?.toString();
      _coverUrl = event['image_url']?.toString();
      _status = event['status']?.toString() ?? 'draft';
      _rejectionReason = event['rejection_reason']?.toString();
      _startsAt = DateTime.tryParse(event['starts_at']?.toString() ?? '');
      _endsAt = DateTime.tryParse(event['ends_at']?.toString() ?? '');
      _tickets
        ..clear()
        ..addAll(types.isEmpty
            ? [_TicketDraft()]
            : types.map(_TicketDraft.fromJson));
      _partners
        ..clear()
        ..addAll(partners.map(_PartnerDraft.fromRow));
      _partnersChanged = false;
      _serviceBookings = bookings
          .where((booking) => booking.eventId == widget.eventId)
          .toList(growable: false);
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickCover() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      setState(() => _uploadingCover = true);
      final coverUrl = await widget.organizerRepository.uploadEventCover(
        await file.readAsBytes(),
        file.name,
      );
      if (mounted) setState(() => _coverUrl = coverUrl);
    } catch (error) {
      if (mounted) setState(() => _error = 'Cover upload failed: $error');
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  Future<void> _pickDateTime({required bool start}) async {
    final initial = (start ? _startsAt : _endsAt) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    setState(() {
      final value =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (start) {
        _startsAt = value;
      } else {
        _endsAt = value;
      }
    });
  }

  Future<void> _save({required bool submit}) async {
    if (_saving || _uploadingCover) return;
    if (!_formKey.currentState!.validate()) return;
    if (_startsAt == null || _endsAt == null) {
      setState(() => _error = 'Choose both start and end times.');
      return;
    }
    if (!_endsAt!.isAfter(_startsAt!)) {
      setState(() => _error = 'End time must be after start time.');
      return;
    }
    setState(() {
      _saving = true;
      _submittingForReview = submit;
      _error = null;
    });
    try {
      final data = <String, dynamic>{
        'description': _description.text.trim(),
      };
      if (!_isLocked) {
        final category = _category?.trim();
        final normalizedCategory =
            category?.isNotEmpty == true ? category : _categories.first;
        data.addAll({
          'title': _title.text.trim(),
          'category': normalizedCategory,
          'image_url': _coverUrl,
          'venue_name': _venueName.text.trim(),
          'address': _venueAddress.text.trim(),
          'lat': double.tryParse(_latitude.text.trim()),
          'lng': double.tryParse(_longitude.text.trim()),
          'starts_at': _startsAt!.toIso8601String(),
          'ends_at': _endsAt!.toIso8601String(),
        });
      }
      final id =
          widget.eventId ?? await widget.organizerRepository.createEvent(data);
      if (widget.eventId != null) {
        await widget.organizerRepository.updateEvent(id, {
          ...data,
          if (!_isLocked) 'status': 'draft',
        });
      }
      await widget.organizerRepository.upsertTicketTypes(
        id,
        _tickets.map((ticket) => ticket.toJson()).toList(),
      );
      if (_partnersChanged) {
        for (final partner in _partners) {
          if (partner.logoBytes != null && partner.logoFileName != null) {
            partner.logoUrl =
                await widget.organizerRepository.uploadPartnerLogo(
              partner.logoBytes!,
              partner.logoFileName!,
            );
          }
        }
        if (!_partnersAvailable) {
          throw StateError(
            'Partner changes could not be saved because the event-partners '
            'database migration is not available.',
          );
        }
        await widget.organizerRepository.saveEventPartners(
          id,
          _partners.map((partner) => partner.toRow()).toList(),
        );
      }
      if (submit) {
        await widget.organizerRepository.submitEventForReview(id);
      }
      if (mounted) {
        if (widget.eventId == null && !submit) {
          context.go('/organizer/events/$id/edit');
        } else {
          context.go('/organizer/events');
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _description,
      _venueName,
      _venueAddress,
      _latitude,
      _longitude,
    ]) {
      controller.dispose();
    }
    for (final ticket in _tickets) {
      ticket.dispose();
    }
    for (final partner in _partners) {
      partner.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.authRepository.isSignedIn ||
        widget.authRepository.currentRole != 'organizer' &&
            widget.authRepository.currentRole != 'super_admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/profile');
      });
    }
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: widget.eventId == null ? 'Create Event' : 'Edit Event',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            if (_status == 'rejected')
              _Notice(
                color: AppColors.error,
                text:
                    'Rejected: ${_rejectionReason ?? 'Please update and resubmit.'}',
              ),
            if (_isLocked)
              const _Notice(
                color: AppColors.purple,
                text:
                    'Published events can only have descriptions and ticket quantities updated.',
              ),
            if (_error != null) _Notice(color: AppColors.error, text: _error!),
            _sectionHeader('Event details'),
            _field(_title, 'Title', maxLength: 100, enabled: !_isLocked),
            _field(_description, 'Description', maxLength: 2000, maxLines: 5),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              style: const TextStyle(color: AppColors.text),
              items: _categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: _isLocked
                  ? null
                  : (value) => setState(() => _category = value),
              validator: (value) => value == null ? 'Choose a category' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            PremiumCard(
              elevated: true,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: AppMotion.normal,
                    child: Text(
                      _uploadingCover ? 'Uploading cover image' : 'Cover image',
                      key: ValueKey(_uploadingCover),
                      style: AppText.h2.copyWith(color: AppColors.text),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_coverUrl != null && _coverUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        _coverUrl!,
                        width: double.infinity,
                        height: 170,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(
                          height: 170,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textMuted,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                      height: 120,
                      child: Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          color: AppColors.textMuted,
                          size: 42,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: _uploadingCover
                        ? 'Uploading cover...'
                        : _coverUrl == null
                            ? 'Choose cover image'
                            : 'Replace cover image',
                    icon: Icons.image_outlined,
                    onPressed: _uploadingCover || _saving || _isLocked
                        ? null
                        : _pickCover,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _sectionHeader('Venue'),
            _field(_venueName, 'Venue name', enabled: !_isLocked),
            _field(_venueAddress, 'Venue address', enabled: !_isLocked),
            Row(
              children: [
                Expanded(
                    child: _field(_latitude, 'Latitude',
                        enabled: !_isLocked,
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(
                    child: _field(_longitude, 'Longitude',
                        enabled: !_isLocked,
                        keyboardType: TextInputType.number)),
              ],
            ),
            _sectionHeader('Schedule'),
            _dateButton('Start', _startsAt, () => _pickDateTime(start: true),
                enabled: !_isLocked),
            _dateButton('End', _endsAt, () => _pickDateTime(start: false),
                enabled: !_isLocked),
            _sectionHeader('Ticket types'),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tickets.length,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final ticket = _tickets.removeAt(oldIndex);
                  _tickets.insert(newIndex, ticket);
                });
              },
              itemBuilder: (context, index) =>
                  _ticketRow(index, _tickets[index]),
            ),
            TextButton.icon(
              onPressed: _isLocked
                  ? null
                  : () => setState(() => _tickets.add(_TicketDraft())),
              icon: const Icon(Icons.add),
              label: const Text('Add ticket type'),
            ),
            if (widget.eventId != null) ...[
              _sectionHeader('Menu items'),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage event food and drink items separately.',
                      style: AppText.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: 'Manage menu items',
                      icon: Icons.restaurant_menu_rounded,
                      onPressed: () => context
                          .push('/organizer/events/${widget.eventId}/venue'),
                    ),
                  ],
                ),
              ),
            ],
            _buildFtServicesSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildPartnersSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: GlassContainer(
            blur: 16,
            color: AppColors.surface.withValues(alpha: .94),
            elevated: true,
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Save draft',
                    isLoading: _saving && !_submittingForReview,
                    isDisabled: !_isFormValid ||
                        _uploadingCover ||
                        _submittingForReview,
                    onPressed: () => _save(submit: false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Submit for review',
                    isLoading: _saving && _submittingForReview,
                    isDisabled: !_isFormValid ||
                        _uploadingCover ||
                        _isLocked ||
                        (_saving && !_submittingForReview),
                    onPressed: () => _save(submit: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.md,
        ),
        child: Text(
          title,
          style: AppText.h2.copyWith(color: AppColors.text),
        ),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    int? maxLength,
    bool enabled = true,
    TextInputType? keyboardType,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: PremiumTextField(
          label: label,
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: (value) => value == null || value.trim().isEmpty
              ? '$label is required'
              : null,
          onChanged: (_) => setState(() {}),
        ),
      );

  Widget _dateButton(String label, DateTime? value, VoidCallback onTap,
          {required bool enabled}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OutlinedButton.icon(
          onPressed: enabled ? onTap : null,
          icon: const Icon(Icons.schedule),
          label: Text(
              '$label: ${value == null ? 'Choose date and time' : value.toLocal()}'),
        ),
      );

  Widget _ticketRow(int index, _TicketDraft ticket) => PremiumCard(
        key: ObjectKey(ticket),
        elevated: true,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.only(top: 30, right: AppSpacing.sm),
                child: Icon(Icons.drag_handle_rounded),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  PremiumTextField(
                    label: 'Ticket name',
                    controller: ticket.name,
                    enabled: !_isLocked,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ticket name is required'
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: PremiumTextField(
                          label: 'Price',
                          controller: ticket.price,
                          enabled: !_isLocked,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) =>
                              num.tryParse(value?.trim() ?? '') == null
                                  ? 'Enter a price'
                                  : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: PremiumTextField(
                          label: 'Quantity',
                          controller: ticket.quantity,
                          enabled: !_isLocked,
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              int.tryParse(value?.trim() ?? '') == null
                                  ? 'Enter a quantity'
                                  : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove ticket type',
              onPressed: _tickets.length == 1 || _isLocked
                  ? null
                  : () => setState(() {
                        final removed = _tickets.removeAt(index);
                        removed.dispose();
                      }),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      );

  Widget _buildFtServicesSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Future Times Services (optional)',
            style: AppText.h2.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add Future Times services to your event',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          if (_loadingServices)
            const LinearProgressIndicator()
          else if (_ftServices.isEmpty)
            const Text(
              'No active services are available right now.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            SizedBox(
              height: 176,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _ftServices.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final service = _ftServices[index];
                  return SizedBox(
                    width: 148,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SizedBox(
                              width: double.infinity,
                              child: service.imageUrl == null ||
                                      service.imageUrl!.isEmpty
                                  ? const ColoredBox(
                                      color: AppColors.surfaceMuted,
                                      child: Icon(
                                        Icons.home_repair_service_outlined,
                                        size: 32,
                                      ),
                                    )
                                  : Image.network(
                                      service.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const ColoredBox(
                                        color: AppColors.surfaceMuted,
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                            child: Text(
                              service.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 4, 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'From ${service.currency} ${service.basePrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Add service',
                                  onPressed: _isLocked || _saving
                                      ? null
                                      : () => _bookService(service),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (widget.eventId == null)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Save this event as a draft first to book services for it.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          if (_serviceBookings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Booked services',
              style: AppText.h2.copyWith(color: AppColors.text),
            ),
            ..._serviceBookings.map(_bookedServiceTile),
          ],
          if (_serviceBookings.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Your event will show the Future Times partner badge.',
              style: TextStyle(
                color: AppColors.purple,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ],
      );

  Widget _bookedServiceTile(FtServiceBooking booking) {
    final unpaid =
        booking.status == 'draft' || booking.status == 'pending_payment';
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        leading: const Icon(Icons.handyman_outlined, color: AppColors.purple),
        title: Text(booking.serviceName ?? 'Future Times service'),
        subtitle: Text(
          '${DateFormat.yMMMd().format(booking.startTime)} · '
          '${booking.quantity} unit(s) · ${booking.status.replaceAll('_', ' ')}',
        ),
        trailing: unpaid
            ? IconButton(
                tooltip: 'Cancel unpaid booking',
                onPressed: _saving ? null : () => _cancelBooking(booking),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              )
            : TextButton(
                onPressed: () => _showPaidBookingSupport(),
                child: const Text('Support'),
              ),
      ),
    );
  }

  Future<void> _bookService(FtService service) async {
    final eventId = widget.eventId;
    if (eventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save the event as a draft before booking services.'),
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FtServiceBookingSheet(
        service: service,
        repository: _ftServicesRepository,
        organizerRepository: widget.organizerRepository,
        paymentRepository: widget.paymentRepository,
        initialEventId: eventId,
        initialStart: _startsAt,
        initialEnd: _endsAt,
      ),
    );
    if (!mounted) return;
    try {
      final bookings = await _ftServicesRepository.myBookings();
      setState(() {
        _serviceBookings = bookings
            .where((booking) => booking.eventId == eventId)
            .toList(growable: false);
      });
    } catch (error) {
      setState(() => _error = 'Could not refresh service bookings: $error');
    }
  }

  Future<void> _cancelBooking(FtServiceBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel service booking?'),
        content: const Text(
          'This booking has no paid deposit and can be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await _ftServicesRepository.cancelUnpaidBooking(booking.id);
      final bookings = await _ftServicesRepository.myBookings();
      if (!mounted) return;
      setState(() {
        _serviceBookings = bookings
            .where((item) => item.eventId == widget.eventId)
            .toList(growable: false);
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not cancel booking: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showPaidBookingSupport() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact support to cancel'),
        content: const Text(
          'A deposit has been paid for this booking. Please contact support '
          'to request cancellation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnersSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Partners (optional)',
            style: AppText.h2.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add event partners',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _partners.length,
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                final partner = _partners.removeAt(oldIndex);
                _partners.insert(newIndex, partner);
                _partnersChanged = true;
              });
            },
            itemBuilder: (context, index) {
              final partner = _partners[index];
              return PremiumCard(
                key: ObjectKey(partner),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.only(right: AppSpacing.sm),
                            child: Icon(Icons.drag_handle_rounded),
                          ),
                        ),
                        Expanded(
                          child: PremiumTextField(
                            label: 'Partner name',
                            controller: partner.name,
                            enabled: !_isLocked,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Partner name is required'
                                    : null,
                            onChanged: (_) => setState(() {
                              _partnersChanged = true;
                            }),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove partner',
                          onPressed: _isLocked
                              ? null
                              : () => setState(() {
                                    _partners.removeAt(index).dispose();
                                    _partnersChanged = true;
                                  }),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    PremiumTextField(
                      label: 'Website URL (optional)',
                      controller: partner.website,
                      enabled: !_isLocked,
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        final uri = Uri.tryParse(text);
                        return uri == null || !uri.hasScheme || uri.host.isEmpty
                            ? 'Enter a valid URL'
                            : null;
                      },
                      onChanged: (_) => setState(() {
                        _partnersChanged = true;
                      }),
                    ),
                    DropdownButton<String>(
                      value: partner.tier,
                      items: const [
                        DropdownMenuItem(
                          value: 'partner',
                          child: Text('Partner'),
                        ),
                        DropdownMenuItem(
                          value: 'featured_partner',
                          child: Text('Featured Partner'),
                        ),
                        DropdownMenuItem(
                          value: 'official_partner',
                          child: Text('Official Partner'),
                        ),
                      ],
                      onChanged: _isLocked
                          ? null
                          : (value) => setState(() {
                                partner.tier = value ?? 'partner';
                                _partnersChanged = true;
                              }),
                    ),
                    Row(
                      children: [
                        if (partner.logoBytes != null)
                          ClipOval(
                            child: Image.memory(
                              partner.logoBytes!,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                            ),
                          )
                        else if (partner.logoUrl != null &&
                            partner.logoUrl!.isNotEmpty)
                          CircleAvatar(
                            radius: 21,
                            backgroundImage: NetworkImage(partner.logoUrl!),
                          )
                        else
                          const CircleAvatar(
                            radius: 21,
                            child: Icon(Icons.business_outlined),
                          ),
                        const SizedBox(width: AppSpacing.sm),
                        TextButton.icon(
                          onPressed: _isLocked
                              ? null
                              : () => _pickPartnerLogo(partner),
                          icon: const Icon(Icons.upload_outlined),
                          label: const Text('Upload logo'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          TextButton.icon(
            onPressed: _isLocked
                ? null
                : () => setState(() {
                      _partners.add(_PartnerDraft());
                      _partnersChanged = true;
                    }),
            icon: const Icon(Icons.add),
            label: const Text('Add partner'),
          ),
        ],
      );

  Future<void> _pickPartnerLogo(_PartnerDraft partner) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        partner.logoBytes = bytes;
        partner.logoFileName = image.name;
        _partnersChanged = true;
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not select logo: $error');
    }
  }
}

class _PartnerDraft {
  _PartnerDraft({
    String? name,
    String? website,
    this.logoUrl,
    this.tier = 'partner',
  })  : name = TextEditingController(text: name),
        website = TextEditingController(text: website);

  factory _PartnerDraft.fromRow(Map<String, dynamic> row) => _PartnerDraft(
        name: row['name']?.toString(),
        website: row['website_url']?.toString(),
        logoUrl: row['logo_url']?.toString(),
        tier: row['tier']?.toString() ?? 'partner',
      );

  final TextEditingController name;
  final TextEditingController website;
  String? logoUrl;
  String tier;
  Uint8List? logoBytes;
  String? logoFileName;

  Map<String, dynamic> toRow() => {
        'name': name.text.trim(),
        'website_url': website.text.trim().isEmpty ? null : website.text.trim(),
        'logo_url': logoUrl,
        'tier': tier,
      };

  void dispose() {
    name.dispose();
    website.dispose();
  }
}

class _TicketDraft {
  _TicketDraft({this.id, String? name, num? price, int? quantity})
      : name = TextEditingController(text: name ?? 'General Admission'),
        price = TextEditingController(text: (price ?? 0).toString()),
        quantity = TextEditingController(text: (quantity ?? 100).toString());

  factory _TicketDraft.fromJson(Map<String, dynamic> json) => _TicketDraft(
        id: json['id']?.toString(),
        name: json['name']?.toString(),
        price: num.tryParse(json['price']?.toString() ?? ''),
        quantity: int.tryParse(json['quantity_total']?.toString() ?? ''),
      );

  final String? id;
  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController quantity;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name.text.trim(),
        'price': num.tryParse(price.text.trim()) ?? 0,
        'quantity_total': int.tryParse(quantity.text.trim()) ?? 0,
        'quantity_available': int.tryParse(quantity.text.trim()) ?? 0,
        'is_active': true,
        'is_visible': true,
      };

  void dispose() {
    name.dispose();
    price.dispose();
    quantity.dispose();
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Text(text,
            style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      );
}
