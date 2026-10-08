import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

class ProfileBadges extends StatelessWidget {
  const ProfileBadges({
    super.key,
    required this.unlocked,
  });

  final Map<String, bool> unlocked;

  static const Map<String, ({String label, IconData icon, String description})>
      _badges = {
    'first_event': (
      label: 'First Event',
      icon: Icons.celebration_rounded,
      description: 'You joined the community and checked into your first event.',
    ),
    'social_10': (
      label: 'Social Butterfly',
      icon: Icons.people_alt_rounded,
      description: 'You have connected with at least 10 friends in the app.',
    ),
    'event_hopper': (
      label: 'Event Hopper',
      icon: Icons.directions_run_rounded,
      description: 'You have attended 10 or more events and keep the momentum going.',
    ),
    'vip': (
      label: 'VIP',
      icon: Icons.workspace_premium_rounded,
      description: 'Your profile qualifies for premium VIP access and perks.',
    ),
    'organizer': (
      label: 'Organizer',
      icon: Icons.event_available_rounded,
      description: 'You are helping shape the community as an organizer.',
    ),
    'early_adopter': (
      label: 'Early Adopter',
      icon: Icons.auto_awesome_rounded,
      description: 'You joined the app during the launch window and helped us grow.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final entries = _badges.entries.toList(growable: false);
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final entry = entries[index];
          final isUnlocked = unlocked[entry.key] ?? false;
          final badge = entry.value;
          return GestureDetector(
            onTap: () => _showBadgeSheet(context, badge, isUnlocked),
            child: SizedBox(
              width: 72,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isUnlocked
                          ? const LinearGradient(
                              colors: [AppColors.purple, AppColors.purpleLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isUnlocked ? null : AppColors.surfaceMuted,
                      boxShadow: isUnlocked
                          ? const [
                              BoxShadow(
                                color: Color(0x408B5CF6),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      badge.icon,
                      color: isUnlocked ? Colors.white : AppColors.textMuted,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.micro.copyWith(
                      color: isUnlocked ? AppColors.text : AppColors.textMuted,
                      fontWeight: isUnlocked ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBadgeSheet(
    BuildContext context,
    ({String label, IconData icon, String description}) badge,
    bool isUnlocked,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isUnlocked
                    ? const LinearGradient(
                        colors: [AppColors.purple, AppColors.purpleLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUnlocked ? null : AppColors.surfaceMuted,
              ),
              child: Icon(
                badge.icon,
                color: isUnlocked ? Colors.white : AppColors.textMuted,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              badge.label,
              style: AppText.h2.copyWith(
                color: isUnlocked ? AppColors.text : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUnlocked
                  ? 'Unlocked'
                  : 'Locked',
              style: AppText.micro.copyWith(
                color: isUnlocked ? AppColors.success : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
