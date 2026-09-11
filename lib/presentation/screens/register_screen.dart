import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../data/repositories/auth_repository.dart';

/// Dedicated sign-up screen.
///
/// Collects Name, Email, Mobile Number and Password, validates them up front,
/// then registers the user through [AuthRepository.signUp], which delegates to
/// Supabase Auth and stores the profile fields (name + phone) in the user's
/// metadata. A loading spinner is shown on the buttons during the network call
/// to prevent double-tapping.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  bool _googleSubmitting = false;
  String? _error;

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final RegExp _textChars = RegExp(r'[A-Za-z]');
  static final RegExp _digit = RegExp(r'[0-9]');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Validates a mobile number. Accepts international (`+263...`) or local
  /// (`07...`) Zimbabwean formats plus common formatting characters, and
  /// requires 9+ numeric digits.
  static bool _isValidPhone(String raw) {
    final value = raw.trim();
    if (value.isEmpty || !value.startsWith('+') && !value.startsWith('0')) {
      return false;
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9 || digits.length > 13) {
      return false;
    }
    // Restrict to Zimbabwean prefix range to keep the check meaningful.
    if (value.startsWith('+') && !value.startsWith('+263')) {
      return false;
    }
    return true;
  }

  /// Requires at least 8 characters with a mix of letters and numbers.
  static bool _isStrongPassword(String value) {
    return value.length >= 8 &&
        _textChars.hasMatch(value) &&
        _digit.hasMatch(value);
  }

  Future<void> _createAccount() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    final password = _password.text;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.authRepository.signUp(
        email: email,
        password: password,
        displayName: name,
        phone: phone,
      );
      if (!mounted) return;
      if (widget.authRepository.isSignedIn) {
        context.go('/profile');
      } else {
        // Email confirmation is required before the session activates.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check your inbox to confirm your email, then sign in.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/login');
      }
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _googleSignIn() async {
    if (_submitting || _googleSubmitting) return;
    setState(() {
      _googleSubmitting = true;
      _error = null;
    });
    try {
      await widget.authRepository.signInWithGoogle();
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _googleSubmitting = false);
    }
  }
@override
  Widget build(BuildContext context) {
    final busy = _submitting || _googleSubmitting;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Brand / header ─────────────────────────────────────────
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        gradient: AppGradients.brand,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Create your account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Join Future Times to save events, claim free tickets and connect with friends.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textMuted, height: 1.45, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // ── Error banner ──────────────────────────────────────────
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // ── Name ──────────────────────────────────────────────────
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      enabled: !busy,
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Enter your full name';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        hintText: 'e.g. Tariro Moyo',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Email ─────────────────────────────────────────────────
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      enabled: !busy,
                      validator: (value) {
                        if (value == null || !_emailPattern.hasMatch(value.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        hintText: 'name@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
// ── Mobile number ─────────────────────────────────────────────────────────
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.tel],
                      enabled: !busy,
                      validator: (value) {
                        if (value == null || !_isValidPhone(value.trim())) {
                          return 'Enter a valid mobile number';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Mobile number',
                        hintText: '+2637XXXXXXXX',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Password ──────────────────────────────────────────────
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      enabled: !busy,
                      onFieldSubmitted: (_) => _createAccount(),
                      validator: (value) {
                        if (value == null || !_isStrongPassword(value)) {
                          return 'At least 8 characters with letters and numbers';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'At least 8 characters',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Create Account button ─────────────────────────────────
                    FilledButton(
                      onPressed: busy ? null : _createAccount,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppColors.purple,
                        disabledBackgroundColor:
                            AppColors.purple.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create Account'),
                    ),
                    const SizedBox(height: 18),
// ── Divider ───────────────────────────────────────────────────────────────
                    const Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 13)),
                        ),
                        Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── Google sign-up ────────────────────────────────────────
                    OutlinedButton(
                      onPressed: busy ? null : _googleSignIn,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: AppColors.text,
                        side:
                            const BorderSide(color: AppColors.border, width: 1.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      child: _googleSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.g_mobiledata_rounded,
                                    color: Color(0xFF4285F4)),
                                SizedBox(width: 10),
                                Text('Continue with Google',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),

                    // ── Link to login ─────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account?',
                            style: TextStyle(color: AppColors.textMuted)),
                        TextButton(
                          onPressed: busy ? null : () => context.go('/login'),
                          child: const Text('Sign In',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}