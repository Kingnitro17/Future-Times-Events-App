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
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: auth.isSignedIn ? _signedIn(auth) : _signedOut()),
      ))),
    );
  }

  Widget _signedOut() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.account_circle_outlined,
            size: 72, color: AppTheme.electricIndigo),
        const SizedBox(height: 16),
        Text('Welcome to Future Times',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Sign in to access your tickets and account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.subtleGrey)),
        const SizedBox(height: 28),
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
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.redAccent))),
        const SizedBox(height: 20),
        FilledButton(
            onPressed: _submitting ? null : _signIn,
            child: Text(_submitting ? 'Signing in...' : 'Sign In')),
      ]);

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
      if (auth.isQaMockSession)
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text('Local QA session · debug builds only',
              style: TextStyle(color: Colors.amber, fontSize: 12)),
        ),
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
          onPressed: _submitting || auth.isQaMockSession
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
