import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/organizer_repository.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/premium_app_bar.dart';
import '../../widgets/common/premium_card.dart';
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
            Text('Welcome back, $name',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text)),
            const SizedBox(height: 6),
            const Text('Keep your events moving forward.',
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                  child: _ActionButton(
                label: 'Create Event',
                icon: Icons.add_rounded,
                onTap: () => context.push('/organizer/events/new'),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _ActionButton(
                label: 'Scan Tickets',
                icon: Icons.qr_code_scanner_rounded,
                onTap: () => context.push('/organizer/scan'),
              )),
            ]),
            const SizedBox(height: 22),
            FutureBuilder<Map<String, dynamic>>(
              future: _stats,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    children: List.generate(
                      4,
                      (_) => const SkeletonCard(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _ErrorCard(onRetry: () => setState(_load));
                }
                final stats = snapshot.data ?? const <String, dynamic>{};
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
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
                );
              },
            ),
            const SizedBox(height: 28),
            const Text('Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
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
                  children: rows.map((row) => _ActivityTile(row: row)).toList(),
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
  Widget build(BuildContext context) => PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.purple),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: AppGradients.brand,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.row});
  final Map<String, dynamic> row;
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: Color(0x147222E3),
          child:
              Icon(Icons.confirmation_number_outlined, color: AppColors.purple),
        ),
        title: Text(row['attendee_name']?.toString() ?? 'Ticket sold',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(row['attendee_email']?.toString() ?? 'New attendee'),
        trailing: Text(row['ticket_number']?.toString() ?? '',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
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
