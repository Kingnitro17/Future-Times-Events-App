import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/organizer_repository.dart';
import '../../widgets/event_network_image.dart';

class OrganizerEventsScreen extends StatefulWidget {
  const OrganizerEventsScreen({
    super.key,
    required this.authRepository,
    required this.organizerRepository,
  });

  final AuthRepository authRepository;
  final OrganizerRepository organizerRepository;

  @override
  State<OrganizerEventsScreen> createState() => _OrganizerEventsScreenState();
}

class _OrganizerEventsScreenState extends State<OrganizerEventsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  String _filter = 'All';
  static const _filters = [
    'All',
    'Draft',
    'Pending',
    'Approved',
    'Published',
    'Ended'
  ];

  @override
  void initState() {
    super.initState();
    _future = widget.organizerRepository.getMyEvents();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Events')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/organizer/events/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Event'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _EventsError(
                onRetry: () => setState(
                    () => _future = widget.organizerRepository.getMyEvents()));
          }
          final all = snapshot.data ?? const [];
          final events = all.where((event) {
            if (_filter == 'All') return true;
            final status = event['status']?.toString() ?? 'draft';
            return status == _filter.toLowerCase() ||
                (_filter == 'Pending' && status == 'pending_review');
          }).toList();
          return Column(children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Row(
                children: _filters
                    .map((filter) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: _filter == filter,
                            onSelected: (_) => setState(() => _filter = filter),
                          ),
                        ))
                    .toList(),
              ),
            ),
            Expanded(
              child: events.isEmpty
                  ? const _EmptyEvents()
                  : RefreshIndicator(
                      onRefresh: () async {
                        setState(() =>
                            _future = widget.organizerRepository.getMyEvents());
                        await _future;
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                        itemCount: events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) =>
                            _EventTile(event: events[index]),
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final Map<String, dynamic> event;
  @override
  Widget build(BuildContext context) {
    final status = event['status']?.toString() ?? 'draft';
    final id = event['id']?.toString() ?? '';
    final date = DateTime.tryParse(event['starts_at']?.toString() ?? '');
    final image = event['image_url']?.toString();
    final title = event['title']?.toString() ??
        event['name']?.toString() ??
        'Untitled event';
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/organizer/events/$id'),
        child: Row(children: [
          SizedBox(
              width: 104,
              height: 104,
              child: EventNetworkImage(
                url: image,
                semanticLabel: '$title cover',
              )),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(date == null ? 'Date TBA' : _date(date),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              _StatusChip(status: status),
            ]),
          )),
        ]),
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'pending_review' => Colors.amber.shade800,
      'approved' => Colors.blue,
      'published' => AppColors.success,
      'live' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.replaceAll('_', ' ').toUpperCase(),
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight:
                  status == 'live' ? FontWeight.w900 : FontWeight.w700)),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  const _EmptyEvents();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.event_busy_rounded,
                size: 54, color: AppColors.textMuted),
            const SizedBox(height: 14),
            const Text('No events yet — create your first event',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/organizer/events/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Event'),
            ),
          ]),
        ),
      );
}

class _EventsError extends StatelessWidget {
  const _EventsError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Could not load your events.'),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}
