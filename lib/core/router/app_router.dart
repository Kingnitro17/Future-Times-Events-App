import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../../data/models/event_model.dart';
import '../../data/models/social_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/social_repository.dart';
import '../../data/repositories/saved_events_repository.dart';
import '../../data/repositories/discovery_preferences_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/organizer_repository.dart';
import '../../presentation/screens/organizer/organizer_home_screen.dart';
import '../../presentation/screens/organizer/organizer_events_screen.dart';
import '../../presentation/screens/organizer/edit_event_screen.dart';
import '../../presentation/screens/organizer/organizer_event_detail_screen.dart';
import '../../presentation/screens/organizer/scan_ticket_screen.dart';
import '../../presentation/screens/organizer/organizer_application_screen.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/repositories/attendance_group_repository.dart';
import '../../presentation/screens/wallet_screen.dart';
import '../../presentation/screens/ride/ride_booking_screen.dart';
import '../../presentation/screens/groups/create_group_screen.dart';
import '../../presentation/screens/groups/group_detail_screen.dart';
import '../../presentation/screens/groups/invites_inbox_screen.dart';
import '../../data/repositories/admin_repository.dart';
import '../../presentation/screens/admin/admin_home_screen.dart';
import '../../presentation/screens/admin/admin_reviews_screen.dart';
import '../../presentation/screens/admin/admin_events_screen.dart';
import '../../presentation/screens/admin/admin_event_detail_screen.dart';
import '../../services/roles/role_service.dart';
import '../../logic/blocs/event/event_bloc.dart';
import '../../logic/blocs/social/social_bloc.dart';
import '../../presentation/screens/details_screen.dart';
import '../../presentation/screens/calendar_screen.dart';
import '../../presentation/screens/event_map_screen.dart';
import '../../presentation/screens/explore_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/map_discovery_screen.dart';
import '../../presentation/screens/launch_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/onboarding_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/register_screen.dart';
import '../../presentation/screens/tickets_screen.dart';
import '../../presentation/screens/saved_events_screen.dart';
import '../../presentation/screens/friends_screen.dart';
import '../../presentation/screens/organizers_screen.dart';
import '../../presentation/screens/organizer_detail_screen.dart';
import '../../presentation/screens/notifications_screen.dart';
import '../../presentation/screens/user_profile_screen.dart';

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
      'Wallet',
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
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
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
                    offset: Offset(0, 10),
                  ),
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
                                  transform:
                                      Matrix4.translationValues(0, -12, 0),
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.brand,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 4),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Color(0x357222E3),
                                          blurRadius: 18,
                                          offset: Offset(0, 8)),
                                    ],
                                  ),
                                  child: Icon(item.$2,
                                      color: Colors.white, size: 27),
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
          ),
        ),
      );
}

class _EventDetailsLoader extends StatefulWidget {
  const _EventDetailsLoader({
    required this.eventId,
    required this.summary,
    required this.eventRepository,
    required this.savedEventsRepository,
    required this.authRepository,
    required this.socialRepository,
    required this.groupRepository,
  });

  final String eventId;
  final EventModel? summary;
  final EventRepository eventRepository;
  final SavedEventsRepository savedEventsRepository;
  final AuthRepository authRepository;
  final SocialRepository socialRepository;
  final AttendanceGroupRepository groupRepository;

  @override
  State<_EventDetailsLoader> createState() => _EventDetailsLoaderState();
}

class _EventDetailsLoaderState extends State<_EventDetailsLoader> {
  Future<EventModel>? _future;

  @override
  void initState() {
    super.initState();
    _future = widget.eventRepository.getEventById(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EventModel>(
      future: _future,
      builder: (context, snapshot) {
        final event = snapshot.data ?? widget.summary;
        if (event == null) {
          return const _EventDetailsSkeleton();
        }
        return BlocProvider(
          create: (_) => SocialBloc(socialRepository: widget.socialRepository),
          child: DetailsScreen(
            event: event,
            savedEventsRepository: widget.savedEventsRepository,
            authRepository: widget.authRepository,
            socialRepository: widget.socialRepository,
            groupRepository: widget.groupRepository,
          ),
        );
      },
    );
  }
}

class _EventDetailsSkeleton extends StatelessWidget {
  const _EventDetailsSkeleton();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ExcludeSemantics(
          child: Column(children: [
            Container(height: 320, color: AppColors.surfaceMuted),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  for (final width in [double.infinity, 240.0, 300.0, 190.0])
                    Container(
                      height: 22,
                      width: width,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ]),
              ),
            ),
          ]),
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
  required NotificationRepository notificationRepository,
  required OrganizerRepository organizerRepository,
  required TicketRepository ticketRepository,
  required WalletRepository walletRepository,
  required RideRepository rideRepository,
  required AttendanceGroupRepository groupRepository,
  required AdminRepository adminRepository,
}) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: rootKey,
    refreshListenable: authRepository,
    initialLocation: '/launch',
    redirect: (context, state) {
      final location = state.uri.path;
      final isAuthRoute = location == '/login' || location == '/register';

      // Keep the launch animation visible while the initial session is
      // resolving. AuthRepository is initialized before the app starts, but
      // this also prevents a transient redirect during deep-link startup.
      if (authRepository.isLoading || location == '/launch') return null;

      if (!authRepository.isSignedIn && !isAuthRoute) {
        if (location == '/groups/join') {
          return '/login?returnUrl=${Uri.encodeComponent(state.uri.toString())}';
        }
        return '/login';
      }
      if (authRepository.isSignedIn && isAuthRoute) {
        return '/';
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'This screen could not be opened.\n${state.error ?? state.uri}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/launch',
        builder: (_, __) => LaunchScreen(showOnboarding: showOnboarding),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) =>
            OnboardingScreen(preferencesRepository: discoveryPreferences),
      ),
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginScreen(
          authRepository: authRepository,
          returnLocation: state.uri.queryParameters['returnUrl'],
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => RegisterScreen(authRepository: authRepository),
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
                        authRepository: authRepository,
                        savedEventsRepository: savedEventsRepository,
                        preferencesRepository: discoveryPreferences,
                        socialRepository: socialRepository)))
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/wallet',
                pageBuilder: (_, __) => NoTransitionPage(
                        child: WalletScreen(
                      authRepository: authRepository,
                      walletRepository: walletRepository,
                    )))
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/explore',
                pageBuilder: (_, __) => NoTransitionPage(
                    child: ExploreScreen(
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
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'profile'),
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: ProfileScreen(
                    authRepository: authRepository,
                    savedEventsRepository: savedEventsRepository,
                    preferencesRepository: discoveryPreferences,
                    socialRepository: socialRepository,
                    notificationRepository: notificationRepository,
                    organizerRepository: organizerRepository,
                    groupRepository: groupRepository,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/tickets',
        builder: (_, __) => TicketsScreen(authRepository: authRepository),
      ),
      GoRoute(
        path: '/ride/book',
        builder: (context, state) => RideBookingScreen(
          authRepository: authRepository,
          rideRepository: rideRepository,
          eventRepository: eventRepository,
          eventId: state.uri.queryParameters['eventId'],
        ),
      ),
      GoRoute(
        path: '/groups/new',
        builder: (context, state) => CreateGroupScreen(
          eventId: state.uri.queryParameters['eventId'] ?? '',
          eventRepository: eventRepository,
          groupRepository: groupRepository,
          friendCount:
              int.tryParse(state.uri.queryParameters['friendCount'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (_, state) => GroupDetailScreen(
          groupId: state.pathParameters['id'] ?? '',
          groupRepository: groupRepository,
          authRepository: authRepository,
          socialRepository: socialRepository,
          eventRepository: eventRepository,
        ),
      ),
      GoRoute(
        path: '/groups/invites',
        builder: (_, state) => InvitesInboxScreen(
          repository: groupRepository,
          initialInviteId: state.uri.queryParameters['inviteId'],
        ),
      ),
      GoRoute(
        path: '/groups/join',
        builder: (_, state) => InvitesInboxScreen(
          repository: groupRepository,
          initialInviteId: state.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: '/saved',
        builder: (_, __) => SavedEventsScreen(
          eventRepository: eventRepository,
          savedEventsRepository: savedEventsRepository,
        ),
      ),
      GoRoute(
        path: '/friends',
        builder: (_, __) => FriendsScreen(socialRepository: socialRepository),
      ),
      GoRoute(
        path: '/organizers',
        builder: (_, __) =>
            OrganizersScreen(socialRepository: socialRepository),
      ),
      GoRoute(
        path: '/organizer/:id',
        builder: (_, state) {
          final org = state.extra is OrganizerModel
              ? state.extra as OrganizerModel
              : OrganizerModel(
                  id: state.pathParameters['id'] ?? '',
                  name: 'Organizer',
                );
          return OrganizerDetailScreen(
            organizer: org,
            socialRepository: socialRepository,
          );
        },
      ),
      GoRoute(
        path: '/user/:id',
        parentNavigatorKey: rootKey,
        builder: (context, state) => UserProfileScreen(
          userId: state.pathParameters['id']!,
          authRepository: authRepository,
          socialRepository: socialRepository,
          eventRepository: eventRepository,
          initialData: state.extra,
        ),
      ),
      // Keep old links working without overlapping the Profile tab route.
      GoRoute(
        path: '/profile/:id',
        redirect: (context, state) => '/user/${state.pathParameters['id']}',
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) =>
            NotificationsScreen(notificationRepository: notificationRepository),
      ),
      GoRoute(
        path: '/events/:slug',
        redirect: (context, state) => '/event/${state.pathParameters['slug']!}',
      ),
      GoRoute(
        path: '/admin/events/:id',
        redirect: (context, state) async {
          final userId = authRepository.user?.id;
          final allowed =
              userId != null && await RoleService.instance.isSuperAdmin(userId);
          return allowed ? null : '/profile';
        },
        builder: (_, state) => AdminEventDetailScreen(
          eventId: state.pathParameters['id']!,
          authRepository: authRepository,
          adminRepository: adminRepository,
        ),
      ),
      GoRoute(
        path: '/admin/events',
        redirect: (context, state) async {
          final userId = authRepository.user?.id;
          final allowed =
              userId != null && await RoleService.instance.isSuperAdmin(userId);
          return allowed ? null : '/profile';
        },
        builder: (_, __) => AdminEventsScreen(
          authRepository: authRepository,
          adminRepository: adminRepository,
        ),
      ),
      GoRoute(
        path: '/admin/reviews',
        redirect: (context, state) async {
          final userId = authRepository.user?.id;
          final allowed =
              userId != null && await RoleService.instance.isSuperAdmin(userId);
          return allowed ? null : '/profile';
        },
        builder: (_, __) => AdminReviewsScreen(
          authRepository: authRepository,
          adminRepository: adminRepository,
        ),
      ),
      GoRoute(
        path: '/admin',
        redirect: (context, state) async {
          final userId = authRepository.user?.id;
          final allowed =
              userId != null && await RoleService.instance.isSuperAdmin(userId);
          return allowed ? null : '/profile';
        },
        builder: (_, __) => AdminHomeScreen(
          authRepository: authRepository,
          adminRepository: adminRepository,
        ),
      ),
      GoRoute(
        path: '/organizer/apply',
        redirect: (context, state) =>
            authRepository.currentRole == 'user' ? null : '/profile',
        builder: (_, __) => OrganizerApplicationScreen(
          authRepository: authRepository,
          organizerRepository: organizerRepository,
        ),
      ),
      GoRoute(
        path: '/organizer',
        builder: (_, __) => OrganizerHomeScreen(
          authRepository: authRepository,
          organizerRepository: organizerRepository,
        ),
      ),
      GoRoute(
        path: '/organizer/events',
        builder: (_, __) => OrganizerEventsScreen(
          authRepository: authRepository,
          organizerRepository: organizerRepository,
        ),
      ),
      GoRoute(
        path: '/organizer/events/new',
        builder: (_, __) => EditEventScreen(
          authRepository: authRepository,
          organizerRepository: organizerRepository,
        ),
      ),
      GoRoute(
        path: '/organizer/events/:id/edit',
        builder: (_, state) => EditEventScreen(
          eventId: state.pathParameters['id'],
          authRepository: authRepository,
          organizerRepository: organizerRepository,
        ),
      ),
      GoRoute(
        path: '/organizer/events/:id',
        builder: (_, state) => OrganizerEventDetailScreen(
          eventId: state.pathParameters['id']!,
          authRepository: authRepository,
          organizerRepository: organizerRepository,
        ),
      ),
      GoRoute(
        path: '/organizer/scan',
        redirect: (context, state) {
          final role = authRepository.currentRole;
          if (role != 'organizer' && role != 'super_admin') {
            return '/profile';
          }
          return null;
        },
        builder: (_, state) => ScanTicketScreen(
          authRepository: authRepository,
          organizerRepository: organizerRepository,
          ticketRepository: ticketRepository,
          initialEventId: state.extra is String ? state.extra as String : null,
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
          return _EventDetailsLoader(
            eventId: state.pathParameters['id']!,
            summary:
                state.extra is EventModel ? state.extra! as EventModel : null,
            eventRepository: eventRepository,
            savedEventsRepository: savedEventsRepository,
            authRepository: authRepository,
            socialRepository: socialRepository,
            groupRepository: groupRepository,
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
}
