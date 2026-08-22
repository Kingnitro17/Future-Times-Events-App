import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/social_repository.dart';
import '../../data/repositories/saved_events_repository.dart';
import '../../data/repositories/discovery_preferences_repository.dart';
import '../../logic/blocs/event/event_bloc.dart';
import '../../logic/blocs/social/social_bloc.dart';
import '../../presentation/screens/details_screen.dart';
import '../../presentation/screens/calendar_screen.dart';
import '../../presentation/screens/event_map_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/map_discovery_screen.dart';
import '../../presentation/screens/onboarding_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/tickets_screen.dart';
import '../../presentation/screens/saved_events_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: navigationShell,
        bottomNavigationBar: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(index,
                initialLocation: index == navigationShell.currentIndex),
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
  required bool showOnboarding,
  required SavedEventsRepository savedEventsRepository,
  required DiscoveryPreferencesRepository discoveryPreferences,
}) =>
    GoRouter(
      initialLocation: showOnboarding ? '/onboarding' : '/',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, __) =>
              OnboardingScreen(preferencesRepository: discoveryPreferences),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => BlocProvider(
            create: (_) => EventBloc(repository: eventRepository),
            child: AppShell(navigationShell: navigationShell),
          ),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/',
                  pageBuilder: (_, __) => NoTransitionPage(
                      child: HomeScreen(
                          savedEventsRepository: savedEventsRepository,
                          preferencesRepository: discoveryPreferences)))
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/tickets',
                  pageBuilder: (_, __) => NoTransitionPage(
                      child: TicketsScreen(authRepository: authRepository)))
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/map',
                  pageBuilder: (_, __) => NoTransitionPage(
                      child: MapDiscoveryScreen(
                          savedEventsRepository: savedEventsRepository)))
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/profile',
                  pageBuilder: (_, __) => NoTransitionPage(
                      child: ProfileScreen(
                          authRepository: authRepository,
                          savedEventsRepository: savedEventsRepository,
                          preferencesRepository: discoveryPreferences)))
            ]),
          ],
        ),
        GoRoute(
          path: '/saved',
          builder: (_, __) => SavedEventsScreen(
            eventRepository: eventRepository,
            savedEventsRepository: savedEventsRepository,
          ),
        ),
        GoRoute(
          path: '/calendar',
          builder: (_, __) => BlocProvider(
            create: (_) => EventBloc(repository: eventRepository),
            child: const CalendarScreen(),
          ),
        ),
        GoRoute(
          path: '/event/:id',
          builder: (context, state) {
            final summary = state.extra as EventModel;
            return FutureBuilder<EventModel>(
              future: eventRepository.getEventById(summary.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                }
                final event = snapshot.data ?? summary;
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(
                        create: (_) =>
                            SocialBloc(socialRepository: socialRepository)),
                  ],
                  child: DetailsScreen(
                      event: event,
                      savedEventsRepository: savedEventsRepository,
                      authRepository: authRepository,
                      socialRepository: socialRepository),
                );
              },
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
