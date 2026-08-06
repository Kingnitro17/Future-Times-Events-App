import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/config/app_config.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../../shared/widgets/ft_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (ctx, state) {
        if (state is AuthAuthenticated) {
          return _AuthedProfile(state: state);
        }
        return _GuestProfile();
      },
    );
  }
}

class _AuthedProfile extends StatelessWidget {
  const _AuthedProfile({required this.state});
  final AuthAuthenticated state;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text('Profile',
            style: AppTypography.h3.copyWith(color: AppColors.text)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: settings screen
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Avatar + name ────────────────────────────────────────────────
          FtCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.violet.withAlpha(30),
                  backgroundImage: profile.avatarUrl != null
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          profile.initials,
                          style: AppTypography.h3.copyWith(
                              color: AppColors.violet, fontSize: 20),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.displayName, style: AppTypography.h4),
                      Text(profile.email, style: AppTypography.caption),
                      if (profile.isVip)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: FtBadge(
                            label: '✦ VIP',
                            variant: FtBadgeVariant.warning,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Stats ─────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: FtCard(
                  child: Column(
                    children: [
                      FtGradientText(
                        '${profile.eventsAttended}',
                        style: AppTypography.h2,
                      ),
                      Text('Events', style: AppTypography.caption),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FtCard(
                  child: Column(
                    children: [
                      FtGradientText(
                        '${profile.loyaltyPoints}',
                        style: AppTypography.h2,
                      ),
                      Text('Points', style: AppTypography.caption),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Menu ────────────────────────────────────────────────────────
          Text('Account', style: AppTypography.overline),
          const SizedBox(height: AppSpacing.sm),
          _MenuTile(
            icon: Icons.confirmation_number_outlined,
            label: 'My Tickets',
            onTap: () => context.go('/tickets'),
          ),
          _MenuTile(
            icon: Icons.person_outline,
            label: 'Edit Profile',
            onTap: () {
              // TODO: edit profile screen
            },
          ),
          if (profile.isOrganizer) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Organizer', style: AppTypography.overline),
            const SizedBox(height: AppSpacing.sm),
            _MenuTile(
              icon: Icons.dashboard_outlined,
              label: 'Organizer Dashboard',
              onTap: () => launchUrl(
                Uri.parse('${AppConfig.appBaseUrl}/organizer'),
              ),
              isExternal: true,
            ),
          ],
          if (profile.isStaff) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Staff', style: AppTypography.overline),
            const SizedBox(height: AppSpacing.sm),
            _MenuTile(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Ticket Scanner',
              onTap: () => context.go('/scanner'),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text('More', style: AppTypography.overline),
          const SizedBox(height: AppSpacing.sm),
          _MenuTile(
            icon: Icons.open_in_browser_rounded,
            label: 'Open Website',
            onTap: () =>
                launchUrl(Uri.parse(AppConfig.appBaseUrl)),
            isExternal: true,
          ),
          _MenuTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            isDestructive: true,
            onTap: () {
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _GuestProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text('Profile',
            style: AppTypography.h3.copyWith(color: AppColors.text)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 72,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Sign in to manage your tickets and profile',
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              FtGradientButton(
                label: 'Sign In',
                onPressed: () => context.go('/auth/login'),
                isFullWidth: false,
                height: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              FtOutlinedButton(
                label: 'Create Account',
                onPressed: () => context.go('/auth/signup'),
                isFullWidth: false,
                height: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isExternal = false,
    this.isDestructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isExternal;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.text;

    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: AppTypography.bodyMedium.copyWith(color: color)),
      trailing: Icon(
        isExternal
            ? Icons.open_in_new_rounded
            : Icons.chevron_right_rounded,
        size: 18,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }
}
