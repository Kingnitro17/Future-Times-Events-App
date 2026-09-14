import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../presentation/widgets/event_network_image.dart';
import '../../../services/roles/role_service.dart';

class AdminEventDetailScreen extends StatefulWidget {
  const AdminEventDetailScreen({
    super.key,
    required this.eventId,
    required this.authRepository,
    required this.adminRepository,
  });

  final String eventId;
  final AuthRepository authRepository;
  final AdminRepository adminRepository;

  @override
  State<AdminEventDetailScreen> createState() => _AdminEventDetailScreenState();
}

class _AdminEventDetailScreenState extends State<AdminEventDetailScreen> {
  late Future<bool> _accessFuture;
  late Future<Map<String, dynamic>> _eventFuture;
  final _attendeeSearch = TextEditingController();
  String _query = '';
  bool _actionBusy = false;

  @override
  void initState() {
    super.initState();
    final userId = widget.authRepository.user?.id;
    _accessFuture = userId == null
        ? Future.value(false)
        : RoleService.instance.isSuperAdmin(userId);
    _eventFuture = widget.adminRepository.getEventAdminView(widget.eventId);
    _attendeeSearch.addListener(() =>
        setState(() => _query = _attendeeSearch.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _attendeeSearch.dispose();
    super.dispose();
  }

  void _reload() => setState(() =>
      _eventFuture = widget.adminRepository.getEventAdminView(widget.eventId));

  Future<void> _approve() async {
    await _runAction(() => widget.adminRepository.approveEvent(widget.eventId),
        'Event approved');
  }

  Future<void> _reject() async {
    final reason = await _reasonDialog('Reject event');
    if (reason != null) {
      await _runAction(
          () => widget.adminRepository.rejectEvent(widget.eventId, reason),
          'Event rejected');
    }
  }

  Future<void> _unpublish() async {
    final reason = await _reasonDialog('Archive event');
    if (reason != null) {
      await _runAction(
          () => widget.adminRepository
              .forceUnpublishEvent(widget.eventId, reason),
          'Event archived');
    }
  }

  Future<void> _runAction(
      Future<void> Function() action, String success) async {
    setState(() => _actionBusy = true);
    try {
      await action();
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<String?> _reasonDialog(String title) async {
    final controller = TextEditingController();
    final key = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: key,
          child: TextFormField(
            controller: controller,
            maxLines: 4,
            maxLength: 500,
            validator: (value) => value == null || value.trim().length < 10
                ? 'Enter at least 10 characters'
                : null,
            decoration: const InputDecoration(
                labelText: 'Reason', border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
        future: _accessFuture,
        builder: (context, access) {
          if (access.connectionState != ConnectionState.done) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (access.data != true) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/profile');
            });
            return const Scaffold(
                body: Center(child: Text('Redirecting to your profile...')));
          }
          return FutureBuilder<Map<String, dynamic>>(
            future: _eventFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError || snapshot.data == null) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Event')),
                  body: _ErrorState(onRetry: _reload),
                );
              }
              return _DetailBody(
                event: snapshot.data!,
                query: _query,
                searchController: _attendeeSearch,
                actionBusy: _actionBusy,
                onApprove: _approve,
                onReject: _reject,
                onPublish: () => _runAction(
                    () => widget.adminRepository
                        .forcePublishEvent(widget.eventId),
                    'Event published'),
                onUnpublish: _unpublish,
                onExport: _export,
              );
            },
          );
        },
      );

  Future<void> _export(List<Map<String, dynamic>> rows, String title) async {
    final csv = StringBuffer('Name,Email,Ticket Number,Status,Check-in Time\n');
    for (final row in rows) {
      final profile = row['profile'] as Map<String, dynamic>?;
      csv.writeln([
        profile?['display_name'] ?? row['attendee_name'] ?? '',
        profile?['email'] ?? row['attendee_email'] ?? '',
        row['ticket_number'] ?? '',
        row['status'] ?? '',
        row['checked_in_at'] ?? '',
      ]
          .map((value) => '"${value.toString().replaceAll('"', '""')}"')
          .join(','));
    }
    await SharePlus.instance.share(
        ShareParams(text: csv.toString(), subject: '$title attendees.csv'));
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.event,
    required this.query,
    required this.searchController,
    required this.actionBusy,
    required this.onApprove,
    required this.onReject,
    required this.onPublish,
    required this.onUnpublish,
    required this.onExport,
  });
  final Map<String, dynamic> event;
  final String query;
  final TextEditingController searchController;
  final bool actionBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;
  final Future<void> Function(List<Map<String, dynamic>>, String) onExport;

  @override
  Widget build(BuildContext context) {
    final status = event['status']?.toString() ?? 'draft';
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
              Tab(text: 'Attendees'),
              Tab(text: 'Sales'),
              Tab(text: 'Audit'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _Overview(
              event: event,
              status: status,
              actionBusy: actionBusy,
              onApprove: onApprove,
              onReject: onReject,
              onPublish: onPublish,
              onUnpublish: onUnpublish,
            ),
            _AttendeesTab(
                event: event,
                query: query,
                controller: searchController,
                onExport: onExport),
            _SalesTab(event: event),
            _AuditTab(event: event),
          ],
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.event,
    required this.status,
    required this.actionBusy,
    required this.onApprove,
    required this.onReject,
    required this.onPublish,
    required this.onUnpublish,
  });
  final Map<String, dynamic> event;
  final String status;
  final bool actionBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;

  @override
  Widget build(BuildContext context) {
    final stats = (event['stats'] as Map?)?.cast<String, dynamic>() ?? {};
    final organizer =
        (event['organizer_profile'] as Map?)?.cast<String, dynamic>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
        SizedBox(
          height: 200,
          child: EventNetworkImage(url: event['image_url']?.toString()),
        ),
        const SizedBox(height: 16),
        Text(event['title']?.toString() ?? 'Untitled event',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        Text('Organizer: ${organizer?['display_name'] ?? 'Unknown'}',
            style: const TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 10),
        _StatusChip(status),
        const SizedBox(height: 14),
        Text(event['description']?.toString() ?? 'No description provided.'),
        const SizedBox(height: 16),
        Row(children: [
          _Stat('Tickets', '${stats['tickets_sold'] ?? 0}'),
          _Stat('Revenue', '\$${stats['revenue'] ?? 0}'),
          _Stat('Check-ins', '${stats['check_ins'] ?? 0}'),
        ]),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (status == 'pending_review') ...[
              FilledButton(
                  onPressed: actionBusy ? null : onApprove,
                  child: const Text('Approve')),
              OutlinedButton(
                  onPressed: actionBusy ? null : onReject,
                  child: const Text('Reject')),
            ],
            if (status == 'approved')
              FilledButton(
                  onPressed: actionBusy ? null : onPublish,
                  child: const Text('Force Publish')),
            if (status == 'published' || status == 'live')
              OutlinedButton(
                  onPressed: actionBusy ? null : onUnpublish,
                  child: const Text('Force Unpublish')),
            OutlinedButton(
              onPressed: () => context.push('/organizer/events/${event['id']}'),
              child: const Text('View as Organizer'),
            ),
            OutlinedButton(
              onPressed: () {
                final slug =
                    event['slug']?.toString() ?? event['id'].toString();
                context.push('/events/$slug');
              },
              child: const Text('View as Public'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AttendeesTab extends StatelessWidget {
  const _AttendeesTab({
    required this.event,
    required this.query,
    required this.controller,
    required this.onExport,
  });
  final Map<String, dynamic> event;
  final String query;
  final TextEditingController controller;
  final Future<void> Function(List<Map<String, dynamic>>, String) onExport;

  @override
  Widget build(BuildContext context) {
    final all =
        (event['attendees'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final rows = all.where((row) {
      final profile = row['profile'] as Map<String, dynamic>?;
      final text =
          '${profile?['display_name'] ?? row['attendee_name'] ?? ''} ${row['ticket_number'] ?? ''}'
              .toLowerCase();
      return query.isEmpty || text.contains(query);
    }).toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
        child: Row(children: [
          Expanded(
              child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search attendees'))),
          IconButton(
              onPressed: () =>
                  onExport(rows, event['title']?.toString() ?? 'event'),
              icon: const Icon(Icons.download_outlined)),
        ]),
      ),
      Expanded(
        child: rows.isEmpty
            ? const _EmptyMessage('No attendees found.')
            : ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: rows.length,
                itemBuilder: (_, index) {
                  final row = rows[index];
                  final profile = row['profile'] as Map<String, dynamic>?;
                  return Card(
                    child: ListTile(
                      title: Text(profile?['display_name']?.toString() ??
                          row['attendee_name']?.toString() ??
                          'Attendee'),
                      subtitle: Text(
                          '${profile?['email'] ?? row['attendee_email'] ?? ''}\n${row['ticket_number'] ?? ''}'),
                      isThreeLine: true,
                      trailing: Text(row['status']?.toString() ?? 'issued'),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

class _SalesTab extends StatelessWidget {
  const _SalesTab({required this.event});
  final Map<String, dynamic> event;
  @override
  Widget build(BuildContext context) {
    final stats = (event['stats'] as Map?)?.cast<String, dynamic>() ?? {};
    final types =
        (event['ticket_types'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(children: [
          _Stat('Sold', '${stats['tickets_sold'] ?? 0}'),
          _Stat('Revenue', '\$${stats['revenue'] ?? 0}'),
          _Stat('Check-ins', '${stats['check_ins'] ?? 0}'),
        ]),
        const SizedBox(height: 20),
        const Text('Ticket sales by type',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        if (types.isEmpty)
          const _EmptyMessage('No ticket types found.')
        else
          ...types.map((type) => Card(
                child: ListTile(
                  title: Text(type['name']?.toString() ?? 'Ticket'),
                  subtitle: Text(
                      'Sold ${type['quantity_sold'] ?? 0} of ${type['quantity_total'] ?? 0}'),
                  trailing: Text('\$${type['price'] ?? 0}'),
                ),
              )),
      ],
    );
  }
}

class _AuditTab extends StatelessWidget {
  const _AuditTab({required this.event});
  final Map<String, dynamic> event;
  @override
  Widget build(BuildContext context) {
    final logs =
        (event['review_log'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (logs.isEmpty) return const _EmptyMessage('No audit entries yet.');
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: logs.length,
      itemBuilder: (_, index) {
        final log = logs[index];
        return ListTile(
          leading: const Icon(Icons.history, color: AppColors.purple),
          title: Text(log['action']?.toString() ?? 'Event update'),
          subtitle: Text(_date(log['created_at'])),
          trailing: Text(log['reason']?.toString() ?? ''),
        );
      },
    );
  }

  static String _date(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null
        ? 'Unknown time'
        : DateFormat.yMMMd().add_jm().format(date.toLocal());
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border)),
          child: Column(children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: AppColors.textMuted)),
          ]),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = status == 'published' || status == 'live'
        ? AppColors.success
        : status == 'rejected'
            ? AppColors.error
            : status == 'pending_review'
                ? Colors.amber.shade800
                : AppColors.textMuted;
    return Chip(
      label: Text(status.replaceAll('_', ' ')),
      labelStyle: TextStyle(color: color),
      backgroundColor: color.withValues(alpha: .1),
      side: BorderSide.none,
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted))));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
      child: FilledButton(onPressed: onRetry, child: const Text('Retry')));
}
