import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/organizer_repository.dart';
import '../../widgets/event_network_image.dart';

class OrganizerEventDetailScreen extends StatefulWidget {
  const OrganizerEventDetailScreen({
    super.key,
    required this.eventId,
    required this.authRepository,
    required this.organizerRepository,
  });

  final String eventId;
  final AuthRepository authRepository;
  final OrganizerRepository organizerRepository;

  @override
  State<OrganizerEventDetailScreen> createState() =>
      _OrganizerEventDetailScreenState();
}

class _OrganizerEventDetailScreenState
    extends State<OrganizerEventDetailScreen> {
  late Future<Map<String, dynamic>> _eventFuture;
  late Future<List<Map<String, dynamic>>> _attendeesFuture;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() =>
        setState(() => _query = _searchController.text.trim().toLowerCase()));
  }

  void _load() {
    _eventFuture = widget.organizerRepository.getEventOwnerView(widget.eventId);
    _attendeesFuture =
        widget.organizerRepository.getEventAttendees(widget.eventId);
  }

  void _reload() => setState(_load);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Scaffold(body: _NotFoundState());
          }
          final event = snapshot.data!;
          return DefaultTabController(
            length: 4,
            child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: Text(event['title']?.toString() ?? 'Event'),
                bottom: const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Ticket Types'),
                    Tab(text: 'Attendees'),
                    Tab(text: 'Scan'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _Overview(
                    event: event,
                    onReload: _reload,
                    repository: widget.organizerRepository,
                  ),
                  _TicketTypesTab(
                    event: event,
                    repository: widget.organizerRepository,
                  ),
                  _AttendeesTab(
                    future: _attendeesFuture,
                    query: _query,
                    controller: _searchController,
                    onExport: (rows) => _export(rows, event['title']),
                  ),
                  _ScanTab(eventId: widget.eventId),
                ],
              ),
            ),
          );
        },
      );

  Future<void> _export(
      List<Map<String, dynamic>> rows, Object? eventTitle) async {
    final csv = StringBuffer('Name,Email,Ticket Number,Status,Check-in Time\n');
    for (final row in rows) {
      final profile = row['profile'] as Map<String, dynamic>?;
      csv.writeln([
        profile?['display_name'] ?? row['attendee_name'] ?? '',
        profile?['email'] ?? row['attendee_email'] ?? '',
        row['ticket_number'] ?? '',
        row['status'] ?? '',
        row['checked_in_at'] ?? '',
      ].map((value) => _csvCell(value)).join(','));
    }
    await SharePlus.instance.share(
      ShareParams(text: csv.toString(), subject: '$eventTitle attendees.csv'),
    );
  }

  String _csvCell(Object value) =>
      '"${value.toString().replaceAll('"', '""')}"';
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.event,
    required this.onReload,
    required this.repository,
  });
  final Map<String, dynamic> event;
  final VoidCallback onReload;
  final OrganizerRepository repository;

  @override
  Widget build(BuildContext context) {
    final status = event['status']?.toString() ?? 'draft';
    final stats = (event['owner_stats'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final logs = (event['review_log'] as List?)?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
        SizedBox(
          height: 190,
          child: EventNetworkImage(
            url: event['image_url']?.toString(),
            semanticLabel: '${event['title'] ?? 'Event'} cover',
          ),
        ),
        const SizedBox(height: 16),
        Text(event['title']?.toString() ?? 'Untitled event',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        _StatusChip(status: status),
        if (event['submitted_at'] != null)
          _InfoRow('Submitted', _formatDate(event['submitted_at'])),
        if (event['reviewed_at'] != null)
          _InfoRow('Reviewed', _formatDate(event['reviewed_at'])),
        if (event['rejection_reason'] != null)
          _InfoRow('Rejection reason', event['rejection_reason'].toString()),
        const SizedBox(height: 14),
        Row(
          children: [
            _Stat('Tickets', '${stats['tickets_sold'] ?? 0}'),
            _Stat('Revenue', '\$${_amount(stats['revenue'])}'),
            _Stat('Check-ins', '${stats['check_ins'] ?? 0}'),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  context.push('/organizer/events/${event['id']}/edit'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
            if (status == 'draft' || status == 'rejected')
              FilledButton(
                onPressed: () => _run(context, () async {
                  await repository.submitForReview(event['id'].toString());
                  onReload();
                }, 'Submitted for review'),
                child: const Text('Submit for Review'),
              ),
            if (status == 'approved')
              FilledButton(
                onPressed: () => _run(context, () async {
                  await repository.publishEvent(event['id'].toString());
                  onReload();
                }, 'Event published'),
                child: const Text('Publish'),
              ),
            OutlinedButton.icon(
              onPressed: () => context.push('/organizer/scan',
                  extra: event['id'].toString()),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Tickets'),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  context.push('/organizer/events/${event['id']}/venue'),
              icon: const Icon(Icons.restaurant_menu_outlined),
              label: const Text('Venue Setup'),
            ),
            FilledButton.icon(
              onPressed: () =>
                  context.push('/organizer/events/${event['id']}/fulfill'),
              icon: const Icon(Icons.room_service_outlined),
              label: const Text('Fulfillment'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Review history',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        if (logs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No review activity yet.',
                style: TextStyle(color: AppColors.textMuted)),
          )
        else
          ...logs.map((log) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(log['action']?.toString() ?? 'Update'),
                subtitle: Text(_formatDate(log['created_at'])),
                trailing: Text(log['reason']?.toString() ?? ''),
              )),
      ],
    );
  }

  static Future<void> _run(BuildContext context, Future<void> Function() action,
      String success) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  static String _formatDate(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null
        ? 'Not available'
        : DateFormat.yMMMd().add_jm().format(date.toLocal());
  }

  static String _amount(Object? value) {
    final amount = num.tryParse(value?.toString() ?? '') ?? 0;
    return amount % 1 == 0
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
  }
}

class _TicketTypesTab extends StatefulWidget {
  const _TicketTypesTab({required this.event, required this.repository});
  final Map<String, dynamic> event;
  final OrganizerRepository repository;

  @override
  State<_TicketTypesTab> createState() => _TicketTypesTabState();
}

class _TicketTypesTabState extends State<_TicketTypesTab> {
  late Future<List<Map<String, dynamic>>> _future;
  final _names = <String, TextEditingController>{};
  final _prices = <String, TextEditingController>{};
  final _quantities = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getTicketTypes(widget.event['id'].toString());
  }

  @override
  void dispose() {
    for (final controller in [
      ..._names.values,
      ..._prices.values,
      ..._quantities.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return const _ErrorState();
          final rows = snapshot.data ?? const [];
          if (rows.isEmpty) return const _EmptyState('No ticket types yet.');
          final editable = widget.event['status'] == 'draft';
          for (final row in rows) {
            final id = row['id'].toString();
            _names.putIfAbsent(
              id,
              () => TextEditingController(
                  text: row['name']?.toString() ?? 'Ticket'),
            );
            _prices.putIfAbsent(
              id,
              () =>
                  TextEditingController(text: row['price']?.toString() ?? '0'),
            );
            _quantities.putIfAbsent(
              id,
              () => TextEditingController(
                  text: row['quantity_total']?.toString() ?? '0'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              ...rows.map((row) {
                final id = row['id'].toString();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _names[id],
                            enabled: editable,
                            decoration:
                                const InputDecoration(labelText: 'Name'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _prices[id],
                            enabled: editable,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration:
                                const InputDecoration(labelText: 'Price'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _quantities[id],
                            enabled: editable,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Qty'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Sold ${row['quantity_sold'] ?? 0}\n'
                            'Left ${row['quantity_available'] ?? 0}'),
                      ],
                    ),
                  ),
                );
              }),
              if (editable)
                FilledButton(
                  onPressed: () async {
                    try {
                      await widget.repository.upsertTicketTypes(
                        widget.event['id'].toString(),
                        rows.map((row) {
                          final id = row['id'].toString();
                          final quantity =
                              int.tryParse(_quantities[id]!.text) ?? 0;
                          return {
                            'id': id,
                            'name': _names[id]!.text.trim(),
                            'price': num.tryParse(_prices[id]!.text) ?? 0,
                            'quantity_total': quantity,
                            'quantity_available': quantity,
                            'quantity_sold': row['quantity_sold'] ?? 0,
                          };
                        }).toList(),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ticket types saved')),
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    }
                  },
                  child: const Text('Save ticket types'),
                ),
            ],
          );
        },
      );
}

class _AttendeesTab extends StatelessWidget {
  const _AttendeesTab({
    required this.future,
    required this.query,
    required this.controller,
    required this.onExport,
  });
  final Future<List<Map<String, dynamic>>> future;
  final String query;
  final TextEditingController controller;
  final ValueChanged<List<Map<String, dynamic>>> onExport;

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return const _ErrorState();
          final all = snapshot.data ?? const [];
          final rows = all.where((row) {
            final profile = row['profile'] as Map<String, dynamic>?;
            final name =
                (profile?['display_name'] ?? row['attendee_name'] ?? '')
                    .toString()
                    .toLowerCase();
            final number = row['ticket_number']?.toString().toLowerCase() ?? '';
            return query.isEmpty ||
                name.contains(query) ||
                number.contains(query);
          }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                child: Row(
                  children: [
                    Expanded(
                        child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search attendees'),
                    )),
                    IconButton(
                        onPressed: () => onExport(rows),
                        tooltip: 'Export CSV',
                        icon: const Icon(Icons.download_outlined)),
                  ],
                ),
              ),
              Expanded(
                child: rows.isEmpty
                    ? const _EmptyState('No attendees found.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(18),
                        itemCount: rows.length,
                        itemBuilder: (_, index) =>
                            _AttendeeTile(row: rows[index]),
                      ),
              ),
            ],
          );
        },
      );
}

class _AttendeeTile extends StatelessWidget {
  const _AttendeeTile({required this.row});
  final Map<String, dynamic> row;
  @override
  Widget build(BuildContext context) {
    final profile = row['profile'] as Map<String, dynamic>?;
    final status = row['status']?.toString() ?? 'issued';
    return Card(
      child: ListTile(
        title: Text(profile?['display_name']?.toString() ??
            row['attendee_name']?.toString() ??
            'Attendee'),
        subtitle: Text(
            '${profile?['email'] ?? row['attendee_email'] ?? ''}\n${row['ticket_number'] ?? ''}'),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status.replaceAll('_', ' '),
                style: TextStyle(
                    color: status == 'checked_in'
                        ? AppColors.success
                        : status == 'cancelled'
                            ? AppColors.error
                            : AppColors.textMuted,
                    fontWeight: FontWeight.w700)),
            if (row['checked_in_at'] != null)
              Text(_date(row['checked_in_at']),
                  style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  static String _date(Object value) {
    final date = DateTime.tryParse(value.toString());
    return date == null ? '' : DateFormat.Md().add_jm().format(date.toLocal());
  }
}

class _ScanTab extends StatelessWidget {
  const _ScanTab({required this.eventId});
  final String eventId;
  @override
  Widget build(BuildContext context) => Center(
        child: FilledButton.icon(
          onPressed: () => context.push('/organizer/scan', extra: eventId),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan tickets for this event'),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('$label: $value',
            style: const TextStyle(color: AppColors.textMuted)),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'pending_review' => Colors.amber.shade800,
      'approved' => Colors.blue,
      'published' || 'live' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.textMuted,
    };
    return Chip(
      label: Text(status.replaceAll('_', ' ').toUpperCase()),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      backgroundColor: color.withValues(alpha: .12),
      side: BorderSide.none,
    );
  }
}

class _NotFoundState extends StatelessWidget {
  const _NotFoundState();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.search_off, size: 52, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text('Event not found.',
              style: TextStyle(fontWeight: FontWeight.w800)),
          TextButton(
              onPressed: () => context.go('/organizer/events'),
              child: const Text('Back to events')),
        ]),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(
      child: Text(message, style: const TextStyle(color: AppColors.textMuted)));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Could not load this data.'));
}
