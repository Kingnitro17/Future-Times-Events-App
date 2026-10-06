import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _pollTimer;
  StreamSubscription<AuthState>? _authSubscription;
  bool _resending = false;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.session?.user.emailConfirmedAt != null) {
        _onConfirmed();
      }
    });
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkConfirmation(),
    );
    _checkConfirmation();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConfirmation() async {
    final confirmed =
        Supabase.instance.client.auth.currentUser?.emailConfirmedAt != null;
    if (confirmed) _onConfirmed();
  }

  void _onConfirmed() {
    if (_confirmed || !mounted) return;
    _confirmed = true;
    _pollTimer?.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email verified!')),
    );
    context.go('/');
  }

  Future<void> _resendEmail() async {
    if (_resending || widget.email.trim().isEmpty) return;
    setState(() => _resending = true);
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent again.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not resend verification email: $error')),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: .1),
                        borderRadius: AppRadius.rXl,
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 64,
                        color: AppColors.purple,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Check your inbox',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We sent a verification link to ${widget.email}. Tap it to activate your account.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: _resending ? null : _resendEmail,
                      child: _resending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Resend email'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Back to sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
