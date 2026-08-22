import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
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
        extendBody: true,
        body: Padding(
          padding: const EdgeInsets.only(bottom: 92),
          child: navigationShell,
        ),
        bottomNavigationBar: _FutureTimesNavigation(
          selectedIndex: navigationShell.currentIndex,
          onSelected: (index) => navigationShell.goBranch(index,
              initialLocation: index == navigationShell.currentIndex),
        ),
      );
}

class _FutureTimesNavigation extends StatelessWidget {
  const _FutureTimesNavigation(
      {required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    ('Home', Icons.home_outlined, Icons.home_rounded),
    (
      'Tickets',
      Icons.confirmation_number_outlined,
      Icons.confirmation_number_rounded
    ),
    ('Explore', Icons.search_rounded, Icons.search_rounded),
    ('Map', Icons.map_outlined, Icons.map_rounded),
    ('Profile', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: .97),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x260A0A14),
                  blurRadius: 24,
                  offset: Offset(0, 10)),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = selectedIndex == index;
              final center = index == 2;
              return Expanded(
                child: Semantics(
                  selected: selected,
                  button: true,
                  label: item.$1,
                  child: InkResponse(
                    onTap: () => onSelected(index),
                    radius: 34,
                    child: AnimatedScale(
                      scale: selected ? 1 : .96,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (center)
                            Container(
                              width: 58,
                              height: 58,
                              transform: Matrix4.translationValues(0, -12, 0),
                              decoration: BoxDecoration(
                                gradient: AppGradients.brand,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 4),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x357222E3),
                                      blurRadius: 18,
                                      offset: Offset(0, 8)),
                                ],
                              ),
                              child:
                                  Icon(item.$2, color: Colors.white, size: 27),
                            )
                          else
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.purple.withValues(alpha: .1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(selected ? item.$3 : item.$2,
                                  color: selected
                                      ? AppColors.purple
                                      : AppColors.textMuted,
                                  size: 23),
                            ),
                          SizedBox(height: center ? 0 : 2),
                          Text(item.$1,
                              maxLines: 1,
                              style: TextStyle(
                                  color: selected
                                      ? AppColors.text
                                      : AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
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
                  path: '/explore',
                  pageBuilder: (_, __) => NoTransitionPage(
                      child: HomeScreen(
                          savedEventsRepository: savedEventsRepository,
                          preferencesRepository: discoveryPreferences)))
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
