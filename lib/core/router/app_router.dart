import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/social_repository.dart';
import '../../data/services/payment_service.dart';
import '../../logic/blocs/booking/booking_bloc.dart';
import '../../logic/blocs/event/event_bloc.dart';
import '../../logic/blocs/social/social_bloc.dart';
import '../../presentation/screens/details_screen.dart';
import '../../presentation/screens/event_map_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/map_discovery_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/tickets_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  static const paths = ['/', '/tickets', '/map', '/profile'];
  int get selectedIndex {
    if (location.startsWith('/tickets')) return 1;
    if (location.startsWith('/map')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: child,
        bottomNavigationBar: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => context.go(paths[index]),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.confirmation_number_outlined),
                  selectedIcon: Icon(Icons.confirmation_number_rounded),
                  label: 'Tickets'),
              NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map_rounded),
                  label: 'Map'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile'),
            ],
          ),
        ),
      );
}

GoRouter buildAppRouter({
  required EventRepository eventRepository,
  required AuthRepository authRepository,
  required SocialRepository socialRepository,
  required PaymentService paymentService,
}) =>
    GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => BlocProvider(
            create: (_) => EventBloc(repository: eventRepository),
            child: AppShell(location: state.uri.path, child: child),
          ),
          routes: [
            GoRoute(
                path: '/',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: HomeScreen())),
            GoRoute(
                path: '/tickets',
                pageBuilder: (_, __) => NoTransitionPage(
                    child: TicketsScreen(authRepository: authRepository))),
            GoRoute(
                path: '/map',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: MapDiscoveryScreen())),
            GoRoute(
                path: '/profile',
                pageBuilder: (_, __) => NoTransitionPage(
                    child: ProfileScreen(authRepository: authRepository))),
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
                        paymentService: paymentService)),
              ],
              child: DetailsScreen(event: event),
            );
          },
        ),
        GoRoute(
          path: '/event/:id/map',
          builder: (_, state) => BlocProvider(
            create: (_) => SocialBloc(socialRepository: socialRepository),
            child: EventMapScreen(event: state.extra as EventModel),
          ),
        ),
      ],
    );
