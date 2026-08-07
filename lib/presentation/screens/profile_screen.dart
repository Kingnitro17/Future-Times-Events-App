import 'package:flutter/material.dart';
import '../../core/errors/app_failure.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.authRepository});
  final AuthRepository authRepository;
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
      backgroundColor: AppTheme.charcoal,
      appBar: AppBar(
          title: const Text('Profile'), backgroundColor: AppTheme.charcoal),
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
        auth.user?.email?.split('@').first ??
        'Future Times member';
    return Column(children: [
      const Icon(Icons.account_circle,
          size: 88, color: AppTheme.electricIndigo),
      const SizedBox(height: 16),
      Text(name, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 6),
      Text(auth.user?.email ?? '',
          style: const TextStyle(color: AppTheme.subtleGrey)),
      if (auth.profileError != null)
        Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(auth.profileError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.amber))),
      const SizedBox(height: 28),
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
}
