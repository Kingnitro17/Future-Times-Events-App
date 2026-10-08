import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/organizer_repository.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/premium_app_bar.dart';
import '../../widgets/common/skeleton.dart';

class OrganizerHomeScreen extends StatefulWidget {
  const OrganizerHomeScreen({
    super.key,
    required this.authRepository,
    required this.organizerRepository,
  });

  final AuthRepository authRepository;
  final OrganizerRepository organizerRepository;

  @override
  State<OrganizerHomeScreen> createState() => _OrganizerHomeScreenState();
}

class _OrganizerHomeScreenState extends State<OrganizerHomeScreen> {
  final _analyticsKey = GlobalKey();
  late Future<Map<String, dynamic>> _stats;
  late Future<List<Map<String, dynamic>>> _activity;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _stats = widget.organizerRepository.getMyStats();
    _activity = widget.organizerRepository.getRecentTicketSales();
  }

  void _viewAnalytics() {
    final targetContext = _analyticsKey.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: AppMotion.normal,
      curve: AppMotion.easeOut,
    );
  }

  void _redirectIfNeeded() {
    if (widget.authRepository.profileLoading) return;
    if (!widget.authRepository.isSignedIn ||
        widget.authRepository.currentRole != 'organizer' &&
            widget.authRepository.currentRole != 'super_admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/profile');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _redirectIfNeeded();
    final profile = widget.authRepository.profile;
    final name = profile?['display_name']?.toString() ??
        widget.authRepository.user?.email?.split('@').first ??
        'Organizer';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PremiumAppBar(
        title: 'Organizer Dashboard',
        showBackButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_load);
          await Future.wait([_stats, _activity]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            Text(
              'Welcome back, $name',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.h1.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 6),
            const Text('Keep your events moving forward.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 22),
            SizedBox(
              height: 106,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _ActionTile(
                    label: 'Create Event',
                    icon: Icons.add_rounded,
                    onTap: () => context.push('/organizer/events/new'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _ActionTile(
                    label: 'Scan Tickets',
                    icon: Icons.qr_code_scanner_rounded,
                    onTap: () => context.push('/organizer/scan'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _ActionTile(
                    label: 'View Analytics',
                    icon: Icons.insights_rounded,
                    onTap: _viewAnalytics,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(key: _analyticsKey),
            FutureBuilder<Map<String, dynamic>>(
              future: _stats,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return AnimatedSwitcher(
                    duration: AppMotion.normal,
                    child: GridView.count(
                      key: const ValueKey('organizer-stats-loading'),
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: List.generate(
                        4,
                        (_) => const SkeletonCard(),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _ErrorCard(onRetry: () => setState(_load));
                }
                final stats = snapshot.data ?? const <String, dynamic>{};
                return AnimatedSwitcher(
                  duration: AppMotion.normal,
                  child: GridView.count(
                    key: const ValueKey('organizer-stats-loaded'),
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _StatCard('Total Events', '${stats['total_events'] ?? 0}',
                          Icons.event_available_rounded),
                      _StatCard('Tickets Sold', '${stats['tickets_sold'] ?? 0}',
                          Icons.confirmation_number_rounded),
                      _StatCard('Revenue', '\$${_amount(stats['revenue'])}',
                          Icons.payments_rounded),
                      _StatCard('Upcoming', '${stats['upcoming_count'] ?? 0}',
                          Icons.upcoming_rounded),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'Recent Activity',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.h2.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _activity,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SkeletonLine();
                }
                if (snapshot.hasError) {
                  return _ErrorCard(onRetry: () => setState(_load));
                }
                final rows = snapshot.data ?? const [];
                if (rows.isEmpty) {
                  return const _EmptyActivity();
                }
                return Column(
                  children: rows
                      .map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ActivityTile(row: row),
                        ),
                      )
                      .toList(),
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
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => GlassCard(
        elevated: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.purple),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.display.copyWith(
                fontSize: 28,
                color: AppColors.text,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.micro.copyWith(color: AppColors.textMuted),
          ),
        ]),
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 148,
        child: GlassCard(
          elevated: true,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.purple),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.row});
  final Map<String, dynamic> row;
  @override
  Widget build(BuildContext context) => GlassCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          leading: const CircleAvatar(
            backgroundColor: Color(0x147222E3),
            child: Icon(
              Icons.confirmation_number_outlined,
              color: AppColors.purple,
            ),
          ),
          title: Text(
            row['attendee_name']?.toString() ?? 'Ticket sold',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            row['attendee_email']?.toString() ?? 'New attendee',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          trailing: SizedBox(
            width: 72,
            child: Text(
              row['ticket_number']?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
        ),
      );
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();
  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.confirmation_number_outlined,
        title: 'No ticket activity yet',
        message: 'Ticket sales will show here when guests book your events.',
        actionLabel: 'Create event',
        onAction: () => context.push('/organizer/events/new'),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => ErrorState(onRetry: onRetry);
}
