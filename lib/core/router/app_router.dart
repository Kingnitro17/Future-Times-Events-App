import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/social_repository.dart';
import '../../data/services/payment_service.dart';
import '../../logic/blocs/booking/booking_bloc.dart';
import '../../logic/blocs/event/event_bloc.dart';
import '../../logic/blocs/social/social_bloc.dart';
import '../../presentation/screens/details_screen.dart';
import '../../presentation/screens/event_map_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../theme/app_theme.dart';

// ── Shell with Bottom Nav ─────────────────────────────────────────────────────

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _tabs = [
    (
      icon: Icons.explore_rounded,
      activeIcon: Icons.explore_rounded,
      label: 'Discover'
    ),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile'
    ),
  ];

  void _onTap(int index, GoRouter router) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        router.go('/');
        break;
      case 1:
        router.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    return Scaffold(
      backgroundColor: AppTheme.charcoal,
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.charcoalSurface,
        selectedIndex: _currentIndex,
        indicatorColor: AppTheme.electricIndigo.withOpacity(0.2),
        onDestinationSelected: (i) => _onTap(i, router),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon:
                      Icon(t.activeIcon, color: AppTheme.electricIndigo),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

// ── Router ────────────────────────────────────────────────────────────────────

GoRouter buildAppRouter({
  required EventRepository eventRepository,
  required SocialRepository socialRepository,
  required PaymentService paymentService,
}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => EventBloc(repository: eventRepository)),
          ],
          child: AppShell(child: child),
        ),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/event/:id',
        builder: (context, state) {
          final event = state.extra as EventModel;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                  create: (_) =>
                      SocialBloc(socialRepository: socialRepository)),
              BlocProvider(
                  create: (_) => BookingBloc(
                        eventRepository: eventRepository,
                        paymentService: paymentService,
                      )),
            ],
            child: DetailsScreen(event: event),
          );
        },
      ),
      GoRoute(
        path: '/event/:id/map',
        builder: (context, state) {
          final event = state.extra as EventModel;
          return BlocProvider(
            create: (_) => SocialBloc(socialRepository: socialRepository),
            child: EventMapScreen(event: event),
          );
        },
      ),
    ],
  );
}
