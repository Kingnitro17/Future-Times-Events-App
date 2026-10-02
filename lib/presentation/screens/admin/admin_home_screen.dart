import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/roles/role_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/premium_app_bar.dart';
import '../../widgets/common/premium_card.dart';
import '../../widgets/common/skeleton.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({
    super.key,
    required this.authRepository,
    required this.adminRepository,
  });

  final AuthRepository authRepository;
  final AdminRepository adminRepository;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Future<bool> _accessFuture;
  late Future<Map<String, dynamic>> _kpisFuture;
  late Future<List<Map<String, dynamic>>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final userId = widget.authRepository.user?.id;
    _accessFuture = userId == null
        ? Future.value(false)
        : RoleService.instance.isSuperAdmin(userId);
    _kpisFuture = widget.adminRepository.getDashboardKpis();
    _eventsFuture = widget.adminRepository.getRecentEvents(limit: 10);
  }

  void _redirectIfNeeded(bool allowed) {
    if (!allowed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/profile');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _accessFuture,
      builder: (context, accessSnapshot) {
        if (accessSnapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: SizedBox(width: 280, child: SkeletonCard())),
          );
        }
        final allowed = accessSnapshot.data == true;
        _redirectIfNeeded(allowed);
        if (!allowed) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('Redirecting to your profile...')),
          );
        }
        return _DashboardBody(
          authRepository: widget.authRepository,
          kpisFuture: _kpisFuture,
          eventsFuture: _eventsFuture,
          onRetry: () => setState(_load),
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.authRepository,
    required this.kpisFuture,
    required this.eventsFuture,
    required this.onRetry,
  });

  final AuthRepository authRepository;
  final Future<Map<String, dynamic>> kpisFuture;
  final Future<List<Map<String, dynamic>>> eventsFuture;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final profile = authRepository.profile;
    final name = profile?['display_name']?.toString() ??
        authRepository.user?.email?.split('@').first ??
        'Admin';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PremiumAppBar(
        title: 'Admin Dashboard',
        showBackButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async => onRetry(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            Text('Welcome back, $name',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text)),
            const SizedBox(height: 6),
            const Text('Here is what is happening across Future Times.',
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 22),
            FutureBuilder<Map<String, dynamic>>(
              future: kpisFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.55,
                    children: List.generate(
                      6,
                      (_) => const SkeletonBox(height: AppSpacing.xxl * 2),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _ErrorCard(onRetry: onRetry);
                }
                final kpis = snapshot.data ?? const <String, dynamic>{};
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _StatCard(
                        'Total Events', kpis['total_events'], Icons.event),
                    _StatCard('Published', kpis['published_events'],
                        Icons.public_rounded),
                    _StatCard('Pending Reviews', kpis['pending_reviews'],
                        Icons.rate_review_outlined),
                    _StatCard('Total Users', kpis['total_users'],
                        Icons.people_outline_rounded),
                    _StatCard('Organizers', kpis['total_organizers'],
                        Icons.business_outlined),
                    _StatCard('Tickets Sold', kpis['tickets_sold'],
                        Icons.confirmation_number_outlined),
                    _StatCard('Revenue', _amount(kpis['revenue']),
                        Icons.payments_outlined),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ActionButton('Review Queue', Icons.rate_review_outlined,
                    () => context.push('/admin/reviews')),
                _ActionButton('All Events', Icons.event_outlined,
                    () => context.push('/admin/events')),
                _ActionButton('Users', Icons.people_outline_rounded,
                    () => context.push('/admin/users')),
                _ActionButton('Applications', Icons.assignment_outlined,
                    () => context.push('/admin/applications')),
              ],
            ),
            const SizedBox(height: 28),
            const Text('Pending Reviews',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SkeletonLine();
                }
                if (snapshot.hasError) return _ErrorCard(onRetry: onRetry);
                final pending = (snapshot.data ?? const [])
                    .where((event) => event['status'] == 'pending_review')
                    .take(3)
                    .toList();
                if (pending.isEmpty) {
                  return _EmptyMessage(
                    message: 'No events are waiting for review.',
                    actionLabel: 'Review queue',
                    onAction: () => context.push('/admin/reviews'),
                  );
                }
                return Column(
                  children: pending
                      .map((event) => _EventTile(event: event, tappable: true))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 28),
            const Text('Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SkeletonLine();
                }
                if (snapshot.hasError) return _ErrorCard(onRetry: onRetry);
                final events = (snapshot.data ?? const []).take(5).toList();
                if (events.isEmpty) {
                  return _EmptyMessage(
                    message: 'No recent event activity.',
                    actionLabel: 'View events',
                    onAction: () => context.push('/admin/events'),
                  );
                }
                return Column(
                  children:
                      events.map((event) => _EventTile(event: event)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _amount(Object? value) {
    final amount = num.tryParse(value?.toString() ?? '') ?? 0;
    return amount % 1 == 0
        ? '\$${amount.toInt()}'
        : '\$${amount.toStringAsFixed(2)}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon);
  final String label;
  final Object? value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.purple),
          const Spacer(),
          Text(value?.toString() ?? '0',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppGradients.brand,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 2),
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 7),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, this.tappable = false});
  final Map<String, dynamic> event;
  final bool tappable;

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: Color(0x147222E3),
        child: Icon(Icons.event_outlined, color: AppColors.purple),
      ),
      title: Text(event['title']?.toString() ?? 'Untitled event',
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
          'Organizer: ${event['organizer_display_name']?.toString() ?? 'Unknown'}'),
      trailing: Text(event['status']?.toString() ?? '',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
    );
    return tappable
        ? InkWell(
            onTap: () {
              final id = event['id']?.toString();
              if (id != null && id.isNotEmpty) {
                context.push('/admin/events/$id');
              }
            },
            child: tile,
          )
        : tile;
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.inbox_outlined,
        title: 'Nothing to review',
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => ErrorState(onRetry: onRetry);
}
