import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/events/presentation/screens/events_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/tickets/presentation/screens/tickets_screen.dart';
import '../../features/tickets/presentation/screens/ticket_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/checkout/presentation/screens/ticket_selection_screen.dart';
import '../../features/shell/main_shell.dart';

/// App router — all routes for Future Times Events.
GoRouter buildAppRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: false,
    refreshListenable: _AuthNotifier(authBloc),

    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthed = authState is AuthAuthenticated;
      final isOnAuthScreen = state.matchedLocation.startsWith('/auth');
      final protectedPaths = ['/tickets', '/profile', '/checkout', '/scanner'];
      final isProtected = protectedPaths.any(
        (p) => state.matchedLocation.startsWith(p),
      );

      if (isProtected && !isAuthed) {
        return '/auth/login?return=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (isAuthed && isOnAuthScreen) return '/home';
      return null;
    },

    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        name: 'signIn',
        builder: (_, state) {
          final returnPath = state.uri.queryParameters['return'];
          return BlocProvider.value(
            value: authBloc,
            child: SignInScreen(returnPath: returnPath),
          );
        },
      ),
      GoRoute(
        path: '/auth/signup',
        name: 'signUp',
        builder: (_, __) => BlocProvider.value(
          value: authBloc,
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/verify',
        name: 'emailVerify',
        builder: (_, state) => _EmailVerificationScreen(
          email: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: '/auth/forgot',
        name: 'forgotPassword',
        builder: (_, __) => BlocProvider.value(
          value: authBloc,
          child: const _ForgotPasswordScreen(),
        ),
      ),

      // ── Main Shell (bottom nav) ─────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/events',
            name: 'events',
            builder: (_, __) => const EventsScreen(),
            routes: [
              GoRoute(
                path: ':slug',
                name: 'eventDetail',
                builder: (_, state) => EventDetailScreen(
                  slug: state.pathParameters['slug']!,
                ),
                routes: [
                  GoRoute(
                    path: 'tickets',
                    name: 'ticketSelection',
                    builder: (_, state) => TicketSelectionScreen(
                      slug: state.pathParameters['slug']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/tickets',
            name: 'tickets',
            builder: (_, __) => const TicketsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'ticketDetail',
                builder: (_, state) => TicketDetailScreen(
                  ticketId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],

    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error?.message}'),
      ),
    ),
  );
}

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this._authBloc) {
    _sub = _authBloc.stream.listen((_) => notifyListeners());
  }

  final AuthBloc _authBloc;
  late final _sub = _authBloc.stream.listen((_) {});

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class _EmailVerificationScreen extends StatelessWidget {
  const _EmailVerificationScreen({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check your email')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read_outlined,
                size: 64, color: Color(0xFF7222E3)),
            const SizedBox(height: 24),
            Text('Verify your email',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'We sent a confirmation link to $email.\nClick it to activate your account.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.go('/auth/login'),
              child: const Text('Back to Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForgotPasswordScreen extends StatefulWidget {
  const _ForgotPasswordScreen();

  @override
  State<_ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<_ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthPasswordResetSent) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text('Reset link sent to ${state.email}'),
            backgroundColor: const Color(0xFF22C55E),
          ));
          ctx.go('/auth/login');
        } else if (state is AuthFailureState) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.failure.message),
            backgroundColor: const Color(0xFFEF4444),
          ));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Reset password')),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    hintText: 'you@example.com',
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 24),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (ctx, state) => FilledButton(
                    onPressed: state is AuthLoading
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              ctx.read<AuthBloc>().add(
                                AuthPasswordResetRequested(_emailCtrl.text.trim()),
                              );
                            }
                          },
                    child: state is AuthLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Send reset link'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
