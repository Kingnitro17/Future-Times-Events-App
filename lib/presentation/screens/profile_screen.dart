import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/errors/app_failure.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/saved_events_repository.dart';
import '../../data/repositories/discovery_preferences_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen(
      {super.key,
      required this.authRepository,
      required this.savedEventsRepository,
      required this.preferencesRepository});
  final AuthRepository authRepository;
  final SavedEventsRepository savedEventsRepository;
  final DiscoveryPreferencesRepository preferencesRepository;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.authRepository.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.authRepository.removeListener(_changed);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.authRepository
          .signIn(email: _email.text, password: _password.text);
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.authRepository;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
              onPressed: () => context.push('/onboarding'),
              tooltip: 'Discovery preferences',
              icon: const Icon(Icons.tune_rounded)),
        ],
      ),
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: auth.isSignedIn ? _signedIn(auth) : _signedOut()),
      ))),
    );
  }

  Widget _signedOut() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _identityCard(
          name: 'Future Times',
          detail:
              'Sign in to sync tickets, saved events and discovery preferences across your devices.',
          status: 'Browsing mode',
        ),
        const SizedBox(height: 28),
        _sectionIntro('DISCOVERY',
            'Shape what you see and keep the events you care about close.'),
        _actionGroup([
          _ProfileAction(
              Icons.bookmark_outline_rounded,
              'Saved Events',
              'Build your shortlist for what happens next.',
              () => context.push('/saved')),
          _ProfileAction(
              Icons.tune_rounded,
              'Interests & Location',
              '${widget.preferencesRepository.city} · ${widget.preferencesRepository.interests.length} interests',
              () => context.push('/onboarding')),
        ]),
        const SizedBox(height: 26),
        _sectionIntro('SUPPORT', 'Help, privacy and product information.'),
        _actionGroup([
          _ProfileAction(Icons.help_outline_rounded, 'Help & Support',
              'Get help with tickets and account access.', _emailSupport),
          _ProfileAction(
              Icons.privacy_tip_outlined,
              'Privacy & Terms',
              'How Future Times protects your information.',
              () => _openWeb('/privacy-policy')),
        ]),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x120A0A14),
                    blurRadius: 20,
                    offset: Offset(0, 8))
              ]),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Unlock your full profile',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
                'Save events, sync tickets and keep your plans available everywhere.',
                style: TextStyle(color: AppColors.textMuted, height: 1.45)),
            const SizedBox(height: 18),
            SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: _showSignIn, child: const Text('Sign in'))),
          ]),
        ),
      ]);

  Widget _identityCard(
      {required String name, required String detail, required String status}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFF0ECFF), Color(0xFFFFEFF9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.purple.withValues(alpha: .18)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x180A0A14), blurRadius: 24, offset: Offset(0, 10))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.purple)),
              child: const Icon(Icons.person_rounded,
                  size: 38, color: AppColors.purple)),
          const Spacer(),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .58),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border)),
              child: Text(status,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 20),
        Text(name,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(detail,
            style: const TextStyle(
                color: AppColors.textSecondary, height: 1.45, fontSize: 15)),
        const SizedBox(height: 18),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _metric(
              Icons.location_on_outlined, widget.preferencesRepository.city),
          _metric(Icons.favorite_border_rounded,
              '${widget.preferencesRepository.interests.length} interests'),
          _metric(Icons.bookmark_outline_rounded,
              '${widget.savedEventsRepository.ids.length} saved'),
        ]),
      ]),
    );
  }

  Widget _metric(IconData icon, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppColors.purple),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ]));

  Widget _sectionIntro(String title, String detail) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3)),
        const SizedBox(height: 6),
        Text(detail, style: const TextStyle(color: AppColors.textMuted)),
      ]));

  Widget _actionGroup(List<_ProfileAction> actions) => Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border)),
      child: Column(children: [
        for (var index = 0; index < actions.length; index++) ...[
          ListTile(
            minTileHeight: 76,
            onTap: actions[index].onTap,
            leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(14)),
                child:
                    Icon(actions[index].icon, color: AppColors.textSecondary)),
            title: Text(actions[index].title,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(actions[index].detail),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted),
          ),
          if (index != actions.length - 1) const Divider(height: 1, indent: 76),
        ]
      ]));

  Future<void> _showSignIn() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
            22, 0, 22, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Welcome back',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 18),
          TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _signIn(),
              decoration: const InputDecoration(labelText: 'Password')),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent))),
          const SizedBox(height: 18),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _submitting ? null : _signIn,
                  child: Text(_submitting ? 'Signing in…' : 'Sign in'))),
        ]),
      ),
    );
  }

  Widget _signedIn(AuthRepository auth) {
    final name = auth.profile?['display_name']?.toString() ??
        auth.displayEmail.split('@').first;
    return Column(children: [
      const Icon(Icons.account_circle,
          size: 88, color: AppTheme.electricIndigo),
      const SizedBox(height: 16),
      Text(name, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 6),
      Text(auth.displayEmail,
          style: const TextStyle(color: AppTheme.subtleGrey)),
      const SizedBox(height: 12),
      OutlinedButton.icon(
          onPressed: () => _editName(name),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Profile')),
      if (auth.profileError != null)
        Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(auth.profileError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.amber))),
      const SizedBox(height: 28),
      ListTile(
        onTap: () => context.push('/saved'),
        leading: const Icon(Icons.bookmark_outline_rounded,
            color: AppTheme.electricIndigo),
        title: const Text('Saved Events'),
        subtitle: const Text('Your shortlist for what happens next'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
      ListTile(
        onTap: () => context.go('/tickets'),
        leading: const Icon(Icons.confirmation_number_outlined,
            color: AppTheme.electricIndigo),
        title: const Text('My Tickets'),
        subtitle: const Text('Active and previously used tickets'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
      ListTile(
        onTap: () => context.push('/onboarding'),
        leading: const Icon(Icons.tune_rounded, color: AppTheme.electricIndigo),
        title: const Text('Discovery Preferences'),
        subtitle: Text(
            '${widget.preferencesRepository.city} · ${widget.preferencesRepository.interests.length} interests'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
      const SizedBox(height: 18),
      _sectionLabel('Support & legal'),
      ListTile(
        onTap: () => _openWeb('/privacy-policy'),
        leading: const Icon(Icons.privacy_tip_outlined),
        title: const Text('Privacy Policy'),
        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
      ),
      ListTile(
        onTap: () => _openWeb('/privacy-policy'),
        leading: const Icon(Icons.description_outlined),
        title: const Text('Terms'),
        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
      ),
      ListTile(
        onTap: _emailSupport,
        leading: const Icon(Icons.help_outline_rounded),
        title: const Text('Help & support'),
        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
      ),
      ListTile(
        onTap: () => _openWeb('/settings'),
        leading: const Icon(Icons.manage_accounts_outlined),
        title: const Text('Account management'),
        subtitle: const Text('Notification settings and account deletion'),
        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
          onPressed: _submitting
              ? null
              : () async {
                  setState(() => _submitting = true);
                  await auth.signOut();
                  if (mounted) setState(() => _submitting = false);
                },
          child: const Text('Sign Out')),
    ]);
  }

  Widget _sectionLabel(String value) => Align(
      alignment: Alignment.centerLeft,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(value.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1))));

  Future<void> _editName(String current) async {
    final controller = TextEditingController(text: current);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    try {
      await widget.authRepository.updateDisplayName(value);
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    }
  }

  Future<void> _openWeb(String path) async {
    final uri = Uri.https('futuretimesevents.com', path);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this page.')));
    }
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@futuretimesevents.com',
      queryParameters: {'subject': 'Future Times app support'},
    );
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Email support@futuretimesevents.com for help.')));
    }
  }
}

class _ProfileAction {
  const _ProfileAction(this.icon, this.title, this.detail, this.onTap);
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
}
