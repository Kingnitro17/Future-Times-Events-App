import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.charcoal,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.charcoal,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Avatar + Name ────────────────────────────────────────────────
          Center(
            child: Column(children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.indigoGradient,
                  boxShadow: AppTheme.indigoGlow,
                ),
                child: const Center(
                  child: Text('U',
                      style: TextStyle(
                          color: AppTheme.pureWhite,
                          fontSize: 40,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Guest User',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              const Text('Sign in to sync your events',
                  style: TextStyle(color: AppTheme.subtleGrey, fontSize: 14)),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Sign In'),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 40),

          // ── Stats ────────────────────────────────────────────────────────
          const Row(children: [
            Expanded(child: _StatCard(value: '0', label: 'Events Attended')),
            SizedBox(width: 12),
            Expanded(child: _StatCard(value: '0', label: 'Check-ins')),
            SizedBox(width: 12),
            Expanded(child: _StatCard(value: '0', label: 'Bookings')),
          ]),

          const SizedBox(height: 36),

          // ── Settings List ─────────────────────────────────────────────────
          Text('Preferences', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.notifications_rounded,
            label: 'Notifications',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.location_on_rounded,
            label: 'Default Location',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.palette_rounded,
            label: 'Appearance',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.electricIndigo.withOpacity(0.15),
                borderRadius: AppTheme.radiusPill,
              ),
              child: const Text('Dark',
                  style: TextStyle(
                      color: AppTheme.electricIndigo,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            onTap: () {},
          ),

          const SizedBox(height: 32),

          Text('About', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'App Version',
            trailing: const Text('1.0.0',
                style: TextStyle(color: AppTheme.subtleGrey, fontSize: 13)),
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () {},
          ),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.charcoalCard,
        borderRadius: AppTheme.radiusMedium,
        border: Border.all(color: AppTheme.charcoalBorder),
      ),
      child: Column(children: [
        Text(value,
            style: const TextStyle(
                color: AppTheme.electricIndigo,
                fontSize: 28,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: AppTheme.subtleGrey, fontSize: 11),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.charcoalCard,
          borderRadius: AppTheme.radiusMedium,
          border: Border.all(color: AppTheme.charcoalBorder),
        ),
        child: Row(children: [
          Icon(icon, color: AppTheme.electricIndigo, size: 20),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppTheme.offWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w500))),
          trailing ??
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.subtleGrey, size: 20),
        ]),
      ),
    );
  }
}
