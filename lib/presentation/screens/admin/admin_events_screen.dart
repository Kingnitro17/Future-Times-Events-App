import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../presentation/widgets/event_network_image.dart';
import '../../../services/roles/role_service.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({
    super.key,
    required this.authRepository,
    required this.adminRepository,
  });

  final AuthRepository authRepository;
  final AdminRepository adminRepository;

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  static const _filters = [
    ('All', 'all'),
    ('Draft', 'draft'),
    ('Pending', 'pending_review'),
    ('Approved', 'approved'),
    ('Published', 'published'),
    ('Live', 'live'),
    ('Ended', 'ended'),
    ('Rejected', 'rejected'),
  ];
  late Future<bool> _accessFuture;
  late Future<List<Map<String, dynamic>>> _eventsFuture;
  String _filter = 'all';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_reload);
    _load();
  }

  void _load() {
    final userId = widget.authRepository.user?.id;
    _accessFuture = userId == null
        ? Future.value(false)
        : RoleService.instance.isSuperAdmin(userId);
    _eventsFuture = _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() =>
      widget.adminRepository.getAllEvents(
        statusFilter: _filter,
        search: _searchController.text,
      );

  void _reload() => setState(() => _eventsFuture = _fetch());

  @override
  void dispose() {
    _searchController
      ..removeListener(_reload)
      ..dispose();
    super.dispose();
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
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('All Events')),
            body: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(
                    children: _filters
                        .map((filter) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(filter.$1),
                                selected: _filter == filter.$2,
                                onSelected: (_) => setState(() {
                                  _filter = filter.$2;
                                  _eventsFuture = _fetch();
                                }),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search title or organizer',
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _eventsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return _ErrorState(onRetry: _reload);
                      }
                      final events = snapshot.data ?? const [];
                      if (events.isEmpty) {
                        return const Center(
                            child: Text('No events found.',
                                style: TextStyle(color: AppColors.textMuted)));
                      }
                      return RefreshIndicator(
                        onRefresh: () async => _reload(),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: events.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) => _EventRow(
                            event: events[index],
                            onTap: () => context
                                .push('/admin/events/${events[index]['id']}'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.onTap});
  final Map<String, dynamic> event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = event['status']?.toString() ?? 'draft';
    final date = DateTime.tryParse(
        (event['starts_at'] ?? event['date'])?.toString() ?? '');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(10),
        leading: SizedBox(
          width: 76,
          height: 76,
          child: EventNetworkImage(url: event['image_url']?.toString()),
        ),
        title: Text(event['title']?.toString() ?? 'Untitled event',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${event['organizer_display_name'] ?? 'Unknown organizer'}\n'
            '${date == null ? 'Date TBA' : DateFormat('MMM d, yyyy').format(date.toLocal())}\n'
            'Tickets: ${event['tickets_sold'] ?? 0} / ${event['capacity'] ?? 0}',
          ),
        ),
        isThreeLine: true,
        trailing: _StatusChip(status),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'published' || 'live' => AppColors.success,
      'pending_review' => Colors.amber.shade800,
      'approved' => Colors.blue,
      'rejected' => AppColors.error,
      _ => AppColors.textMuted,
    };
    return Chip(
      label: Text(status.replaceAll('_', ' ')),
      labelStyle: TextStyle(color: color, fontSize: 11),
      backgroundColor: color.withValues(alpha: .1),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      );
}
