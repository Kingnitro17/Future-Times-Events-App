import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../data/models/ft_service.dart';
import '../../../data/models/ft_service_availability.dart';
import '../../../data/models/payment_transaction.dart';
import '../../../data/repositories/ft_services_repository.dart';
import '../../../data/repositories/organizer_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../services/payments/payment_gateway.dart';

class FtServiceDetailScreen extends StatefulWidget {
  FtServiceDetailScreen({
    super.key,
    required this.serviceId,
    required this.organizerRepository,
    required this.paymentRepository,
    FtServicesRepository? repository,
  }) : repository = repository ?? FtServicesRepository();

  final String serviceId;
  final FtServicesRepository repository;
  final OrganizerRepository organizerRepository;
  final PaymentRepository paymentRepository;

  @override
  State<FtServiceDetailScreen> createState() => _FtServiceDetailScreenState();
}

class _FtServiceDetailScreenState extends State<FtServiceDetailScreen> {
  late Future<FtService?> _serviceFuture;

  @override
  void initState() {
    super.initState();
    _serviceFuture = widget.repository.getService(widget.serviceId);
  }

  void _retry() => setState(
      () => _serviceFuture = widget.repository.getService(widget.serviceId));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Service details')),
        body: FutureBuilder<FtService?>(
          future: _serviceFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorState(
                message: 'Could not load this service. ${snapshot.error}',
                onRetry: _retry,
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final service = snapshot.data;
            if (service == null) {
              return const Center(child: Text('This service is unavailable.'));
            }
            return _ServiceDetails(
              service: service,
              repository: widget.repository,
              organizerRepository: widget.organizerRepository,
              paymentRepository: widget.paymentRepository,
            );
          },
        ),
      );
}

class _ServiceDetails extends StatelessWidget {
  const _ServiceDetails({
    required this.service,
    required this.repository,
    required this.organizerRepository,
    required this.paymentRepository,
  });

  final FtService service;
  final FtServicesRepository repository;
  final OrganizerRepository organizerRepository;
  final PaymentRepository paymentRepository;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(14, (index) {
      final date = DateTime.now();
      final day = DateTime(date.year, date.month, date.day + index);
      return day;
    });
    final availability = Future.wait(days.map((date) {
      return repository.checkAvailability(
        serviceId: service.id,
        start: date,
        end: date.add(const Duration(days: 1)),
      );
    }));

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: service.imageUrl == null || service.imageUrl!.isEmpty
                ? const _ServiceImageFallback()
                : Image.network(
                    service.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _ServiceImageFallback(),
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const ColoredBox(color: AppColors.surfaceMuted),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                service.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            _CategoryPill(category: service.category),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${service.currency} ${service.basePrice.toStringAsFixed(2)} per ${service.unit}',
          style: const TextStyle(
            color: AppColors.purple,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${service.depositPercent}% deposit required — '
          '${service.currency} ${(service.basePrice * service.depositPercent / 100).toStringAsFixed(2)} per unit',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        if ((service.description ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(service.description!,
              style:
                  const TextStyle(color: AppColors.textSecondary, height: 1.5)),
        ],
        const SizedBox(height: 24),
        const Text(
          'Availability',
          style: TextStyle(
              color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<FtServiceAvailability>>(
          future: availability,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Availability could not be checked. ${snapshot.error}',
                style: const TextStyle(color: AppColors.error),
              );
            }
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 90,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < days.length; index++)
                  _AvailabilityDay(
                    date: days[index],
                    availability: snapshot.data![index],
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 26),
        FilledButton.icon(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => _BookingSheet(
              service: service,
              repository: repository,
              organizerRepository: organizerRepository,
              paymentRepository: paymentRepository,
            ),
          ),
          icon: const Icon(Icons.handyman_outlined),
          label: const Text('Hire for an event'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.purple,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }
}

class _AvailabilityDay extends StatelessWidget {
  const _AvailabilityDay({required this.date, required this.availability});

  final DateTime date;
  final FtServiceAvailability availability;

  @override
  Widget build(BuildContext context) {
    final color = availability.available == 0
        ? AppColors.error
        : availability.available < availability.total
            ? const Color(0xFFE6A700)
            : AppColors.success;
    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Column(
        children: [
          Text(DateFormat('EEE').format(date),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 3),
          Text(DateFormat('d MMM').format(date),
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.text,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text('${availability.available} left',
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          category.isEmpty
              ? 'Service'
              : '${category[0].toUpperCase()}${category.substring(1)}',
          style: const TextStyle(
              color: AppColors.purple,
              fontSize: 12,
              fontWeight: FontWeight.w700),
        ),
      );
}

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({
    required this.service,
    required this.repository,
    required this.organizerRepository,
    required this.paymentRepository,
  });

  final FtService service;
  final FtServicesRepository repository;
  final OrganizerRepository organizerRepository;
  final PaymentRepository paymentRepository;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  late Future<List<Map<String, dynamic>>> _eventsFuture;
  final _notes = TextEditingController();
  String? _eventId;
  DateTime? _start;
  DateTime? _end;
  FtServiceAvailability? _availability;
  bool _checkingAvailability = false;
  bool _submitting = false;
  int _quantity = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _eventsFuture = widget.organizerRepository.getMyEvents();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _eligibleEvents(
      List<Map<String, dynamic>> events) {
    final now = DateTime.now();
    return events.where((event) {
      final status = event['status']?.toString();
      final id = event['id']?.toString();
      final start = DateTime.tryParse(
        event['starts_at']?.toString() ?? event['date']?.toString() ?? '',
      );
      return (status == 'published' || status == 'draft') &&
          id != null &&
          id.isNotEmpty &&
          start != null &&
          start.isAfter(now);
    }).toList();
  }

  void _selectEvent(Map<String, dynamic>? event) {
    setState(() {
      _eventId = event?['id']?.toString();
      final startsAt = DateTime.tryParse(
        event?['starts_at']?.toString() ?? event?['date']?.toString() ?? '',
      );
      final endsAt = DateTime.tryParse(
        event?['ends_at']?.toString() ?? event?['end_time']?.toString() ?? '',
      );
      _start = startsAt;
      _end = endsAt != null && startsAt != null && endsAt.isAfter(startsAt)
          ? endsAt
          : startsAt?.add(const Duration(hours: 4));
      _availability = null;
      _error = null;
    });
    if (_start != null && _end != null) _refreshAvailability();
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final initialStart = _start ?? now;
    final initialEnd = _end ?? now.add(const Duration(days: 1));
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
      initialDateRange: DateTimeRange(
        start:
            DateTime(initialStart.year, initialStart.month, initialStart.day),
        end: DateTime(initialEnd.year, initialEnd.month, initialEnd.day)
                .isBefore(DateTime(
                    initialStart.year, initialStart.month, initialStart.day))
            ? DateTime(initialStart.year, initialStart.month, initialStart.day)
            : DateTime(initialEnd.year, initialEnd.month, initialEnd.day),
      ),
    );
    if (picked == null || !mounted) return;
    final startTime = _start ?? now;
    final endTime = _end ?? startTime.add(const Duration(hours: 4));
    setState(() {
      _start = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
        startTime.hour,
        startTime.minute,
      );
      _end = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        endTime.hour,
        endTime.minute,
      );
      if (!_end!.isAfter(_start!)) {
        _end = _start!.add(const Duration(hours: 4));
      }
      _availability = null;
    });
    await _refreshAvailability();
  }

  Future<void> _refreshAvailability() async {
    final start = _start;
    final end = _end;
    if (start == null || end == null || !end.isAfter(start)) return;
    setState(() {
      _checkingAvailability = true;
      _error = null;
    });
    try {
      final availability = await widget.repository.checkAvailability(
        serviceId: widget.service.id,
        start: start,
        end: end,
      );
      if (!mounted) return;
      setState(() {
        _availability = availability;
        _quantity = _quantity.clamp(
          1,
          availability.available == 0 ? 1 : availability.available,
        );
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Availability check failed: $error');
    } finally {
      if (mounted) setState(() => _checkingAvailability = false);
    }
  }

  Future<void> _submit() async {
    final eventId = _eventId;
    final start = _start;
    final end = _end;
    if (eventId == null || start == null || end == null) {
      setState(() => _error = 'Select an event and booking dates first.');
      return;
    }
    if (_availability == null || _availability!.available < _quantity) {
      await _refreshAvailability();
      if (!mounted) return;
      if (_availability == null || _availability!.available < _quantity) {
        setState(() =>
            _error = 'There is not enough availability for this request.');
        return;
      }
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    String? paidPaymentId;
    var paidDeposit = 0.0;
    try {
      final bookingId = await widget.repository.requestBooking(
        serviceId: widget.service.id,
        eventId: eventId,
        quantity: _quantity,
        start: start,
        end: end,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      final deposit = widget.service.basePrice *
          _quantity *
          widget.service.depositPercent /
          100;
      final payment = await widget.paymentRepository.initiateCharge(
        userId: widget.paymentRepository.clientUserId,
        amount: deposit,
        currency: widget.service.currency,
        purpose: PaymentPurpose.service,
        gatewayId: 'manual',
        relatedEntityId: bookingId,
      );
      if (payment.status != PaymentStatus.paid) {
        throw StateError('Deposit payment did not complete.');
      }
      paidPaymentId = payment.id;
      paidDeposit = deposit;
      await widget.repository.confirmBooking(
        bookingId: bookingId,
        paymentTransactionId: payment.id,
      );
      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.pop();
      await showDialog<void>(
        context: navigator.context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Booking requested'),
          content: const Text(
            'Your deposit was received. Your service booking is awaiting review.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                navigator.context.go('/wallet');
              },
              child: const Text('View in wallet'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      var message = error.toString();
      if (paidPaymentId != null && _looksLikeConflict(error)) {
        try {
          await widget.paymentRepository.refund(paidPaymentId, paidDeposit);
        } catch (refundError) {
          message = '$message Deposit refund also failed: $refundError';
        }
      }
      setState(() {
        _error = message;
        _submitting = false;
      });
      if (_looksLikeConflict(error)) _showConflictDialog();
      return;
    }
    if (mounted) setState(() => _submitting = false);
  }

  bool _looksLikeConflict(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('no longer available') ||
        message.contains('inventory conflict') ||
        message.contains('booking confirmation failed');
  }

  Future<void> _showConflictDialog() async {
    final retry = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Someone just booked the last unit'),
        content: const Text(
          'Availability changed while your deposit was processing. Check the dates and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
    if (retry == true && mounted) {
      await _refreshAvailability();
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorState(
                message: 'Could not load your events. ${snapshot.error}',
                onRetry: () => setState(() =>
                    _eventsFuture = widget.organizerRepository.getMyEvents()),
              );
            }
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final events = _eligibleEvents(snapshot.data!);
            if (events.isEmpty) {
              return const SizedBox(
                height: 240,
                child: Center(
                  child: Text(
                    'You need an upcoming published or draft event to request a service.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text('Request ${widget.service.name}',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _eventId,
                    decoration: const InputDecoration(
                      labelText: 'Choose your event',
                      border: OutlineInputBorder(),
                    ),
                    items: events
                        .map((event) => DropdownMenuItem(
                              value: event['id']?.toString(),
                              child: Text(
                                event['title']?.toString() ?? 'Untitled event',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: _submitting
                        ? null
                        : (id) => _selectEvent(events.firstWhere(
                              (event) => event['id']?.toString() == id,
                            )),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed:
                        _submitting || _eventId == null ? null : _pickDates,
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(_start == null || _end == null
                        ? 'Choose dates'
                        : '${DateFormat('d MMM yyyy').format(_start!)} – ${DateFormat('d MMM yyyy').format(_end!)}'),
                  ),
                  const SizedBox(height: 10),
                  if (_checkingAvailability)
                    const LinearProgressIndicator()
                  else if (_availability != null)
                    Text(
                      '${_availability!.available} of ${_availability!.total} available for these dates',
                      style: TextStyle(
                        color: _availability!.available == 0
                            ? AppColors.error
                            : AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Expanded(child: Text('Quantity')),
                      IconButton(
                        onPressed: _quantity <= 1 || _submitting
                            ? null
                            : () => setState(() => _quantity--),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_quantity',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      IconButton(
                        onPressed: _submitting ||
                                (_availability != null &&
                                    _quantity >= _availability!.available)
                            ? null
                            : () => setState(() => _quantity++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _notes,
                    enabled: !_submitting,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BookingSummary(
                    service: widget.service,
                    quantity: _quantity,
                    start: _start,
                    end: _end,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!,
                        style: const TextStyle(color: AppColors.error)),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ||
                              _eventId == null ||
                              _start == null ||
                              _end == null ||
                              _checkingAvailability ||
                              (_availability != null &&
                                  _availability!.available < _quantity)
                          ? null
                          : _submit,
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Reserve & pay deposit'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({
    required this.service,
    required this.quantity,
    required this.start,
    required this.end,
  });

  final FtService service;
  final int quantity;
  final DateTime? start;
  final DateTime? end;

  @override
  Widget build(BuildContext context) {
    final subtotal = service.basePrice * quantity;
    final deposit = subtotal * service.depositPercent / 100;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(service.name,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          if (start != null && end != null)
            Text(
              '${DateFormat('d MMM').format(start!)} – ${DateFormat('d MMM yyyy').format(end!)} · $quantity ${quantity == 1 ? 'unit' : 'units'}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Subtotal',
            value: '${service.currency} ${subtotal.toStringAsFixed(2)}',
          ),
          _SummaryRow(
            label: 'Deposit due now (${service.depositPercent}%)',
            value: '${service.currency} ${deposit.toStringAsFixed(2)}',
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontWeight:
                            emphasized ? FontWeight.w800 : FontWeight.w500))),
            Text(value,
                style: TextStyle(
                    fontWeight:
                        emphasized ? FontWeight.w800 : FontWeight.w500)),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
}

class _ServiceImageFallback extends StatelessWidget {
  const _ServiceImageFallback();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(gradient: AppGradients.brand),
        child: Center(
          child: Icon(Icons.handyman_outlined, color: Colors.white, size: 42),
        ),
      );
}
