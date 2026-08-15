import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key, required this.authRepository});
  final AuthRepository authRepository;

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  @override
  void initState() {
    super.initState();
    widget.authRepository.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.authRepository.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = widget.authRepository.isSignedIn;
    return Scaffold(
      appBar: AppBar(title: const Text('My tickets')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                      color: AppColors.surfaceMuted, shape: BoxShape.circle),
                  child: Icon(
                      signedIn
                          ? Icons.confirmation_number_outlined
                          : Icons.lock_outline_rounded,
                      size: 42,
                      color: AppColors.purple),
                ),
                const SizedBox(height: 24),
                Text(signedIn ? 'No tickets yet' : 'Your tickets, in one place',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(
                  signedIn
                      ? 'Tickets you claim or buy will appear here. We never create demo tickets or expose private QR credentials.'
                      : 'Sign in from Profile to securely access tickets linked to your Future Times account.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
