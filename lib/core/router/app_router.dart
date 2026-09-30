import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../presentation/screens/organizer/venue_setup_screen.dart';
import '../../presentation/screens/organizer/edit_table_screen.dart';
import '../../presentation/screens/organizer/edit_menu_item_screen.dart';
import '../../presentation/screens/venue/table_picker_screen.dart';
import '../../presentation/screens/venue/menu_order_screen.dart';
import '../../presentation/screens/organizer/scan_ticket_screen.dart';
import '../../presentation/screens/organizer/venue_fulfillment_screen.dart';
import '../../presentation/screens/organizer/organizer_application_screen.dart';
import '../../presentation/screens/organizer/organizer_profile_photo_screen.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/repositories/attendance_group_repository.dart';
import '../../data/repositories/venue_commerce_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/venue_table.dart';
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
import '../../presentation/screens/admin/admin_users_screen.dart';
import '../../presentation/screens/admin/admin_applications_screen.dart';
import '../../presentation/screens/profile/forgot_password_screen.dart';
import '../../presentation/screens/profile/account_settings_screen.dart';
import '../../presentation/screens/profile/security_screen.dart';
import '../../presentation/screens/profile/reset_password_screen.dart';
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
import '../../presentation/screens/ft_services/ft_services_list_screen.dart';
import '../../presentation/screens/ft_services/ft_service_detail_screen.dart';

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
  const _FutureTimesNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });
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
                  return Expanded(
                    child: Semantics(
                      selected: selected,
                      button: true,
                      label: item.$1,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onSelected(index);
                        },
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                              transform: selected
                                  ? Matrix4.translationValues(0, -12, 0)
                                  : Matrix4.identity(),
                              width: selected ? 56 : 40,
                              height: selected ? 56 : 30,
                              decoration: selected
                                  ? BoxDecoration(
                                      gradient: AppGradients.brand,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 3.5),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x4D7222E3),
                                          blurRadius: 16,
                                          spreadRadius: 1,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    )
                                  : const BoxDecoration(
                                      color: Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    selected ? item.$3 : item.$2,
                                    key: ValueKey('${item.$1}_$selected'),
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    size: selected ? 26 : 22,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: selected ? 0 : 2),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: TextStyle(
                                color: selected
                                    ? AppColors.purple
                                    : AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                              child: Text(item.$1, maxLines: 1),
                            ),
                          ],
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
    required this.venueCommerceRepository,
  });

  final String eventId;
  final EventModel? summary;
  final EventRepository eventRepository;
  final SavedEventsRepository savedEventsRepository;
  final AuthRepository authRepository;
  final SocialRepository socialRepository;
  final AttendanceGroupRepository groupRepository;
  final VenueCommerceRepository venueCommerceRepository;

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
            venueCommerceRepository: widget.venueCommerceRepository,
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

String? _organizerToolsRedirect(
    AuthRepository authRepository, GoRouterState state) {
  final role = authRepository.currentRole;
  if (role == null && authRepository.profileLoading) return null;
  if (role != 'organizer' && role != 'super_admin') return '/profile';

  if (role == 'organizer') {
    final avatarUrl = authRepository.profile?['avatar_url']?.toString() ??
        authRepository.user?.userMetadata?['avatar_url']?.toString();
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return '/organizer/complete-profile?returnUrl='
          '${Uri.encodeComponent(state.uri.toString())}';
    }
  }
  return null;
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
  required VenueCommerceRepository venueCommerceRepository,
  required PaymentRepository paymentRepository,
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
      if (authRepository.isLoading) return null;
      if (authRepository.passwordRecoveryPending &&
          location != '/reset-password') {
        return '/reset-password';
      }
      if (location == '/launch') return null;

      if (!authRepository.isSignedIn &&
          !isAuthRoute &&
          location != '/forgot-password') {
        return '/login?returnUrl=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (authRepository.isSignedIn &&
          (isAuthRoute || location == '/onboarding')) {
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
      GoRoute(
        path: '/forgot-password',
        builder: (_, state) => ForgotPasswordScreen(
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/reset-password',
        redirect: (_, __) =>
            authRepository.passwordRecoveryPending ? null : '/security',
        builder: (_, __) => ResetPasswordScreen(
          authRepository: authRepository,
        ),
      ),
      GoRoute(
        path: '/account-settings',
        builder: (_, __) => AccountSettingsScreen(
          authRepository: authRepository,
        ),
      ),
      GoRoute(
        path: '/security',
        builder: (_, __) => SecurityScreen(
          authRepository: authRepository,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
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
        path: '/ft-services',
        builder: (_, __) => FtServicesListScreen(),
      ),
      GoRoute(
        path: '/ft-services/:id',
        builder: (_, state) => FtServiceDetailScreen(
          serviceId: state.pathParameters['id']!,
          organizerRepository: organizerRepository,
          paymentRepository: paymentRepository,
        ),
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
        path: '/admin/users',
        redirect: (context, state) async {
          final userId = authRepository.user?.id;
          final allowed =
              userId != null && await RoleService.instance.isSuperAdmin(userId);
          return allowed ? null : '/profile';
        },
        builder: (_, __) => AdminUsersScreen(
          authRepository: authRepository,
          adminRepository: adminRepository,
        ),
      ),
      GoRoute(
        path: '/admin/applications',
        redirect: (context, state) async {
          final userId = authRepository.user?.id;
          final allowed =
              userId != null && await RoleService.instance.isSuperAdmin(userId);
          return allowed ? null : '/profile';
        },
        builder: (_, __) => AdminApplicationsScreen(
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
        path: '/organizer/complete-profile',
        builder: (_, state) => OrganizerProfilePhotoScreen(
          authRepository: authRepository,
          returnLocation: state.uri.queryParameters['returnUrl'],
        ),
      ),
      GoRoute(
        path: '/organizer',
        redirect: (context, state) =>
            _organizerToolsRedirect(authRepository, state),
        builder: (_, __) => OrganizerHomeScreen(
          authRepository: authRepository,
          organizerRepository: organizerRepository,
        ),
      ),
      GoRoute(
        path: '/organizer/events',
        redirect: (context, state) =>
            _organizerToolsRedirect(authRepository, state),
        builder: (_, __) => OrganizerEventsScreen(
          authRepository: authRepository,
          organizerRepository: organizerRepository,
        ),
      ),
      GoRoute(
        path: '/organizer/events/new',
        redirect: (context, state) =>
            _organizerToolsRedirect(authRepository, state),
        builder: (_, __) => EditEventScreen(
          authRepository: authRepository,
          organizerRepository: organizerRepository,
          paymentRepository: paymentRepository,
        ),
      ),
      GoRoute(
        path: '/organizer/events/:id/edit',
        redirect: (context, state) =>
            _organizerToolsRedirect(authRepository, state),
        builder: (_, state) => EditEventScreen(
          eventId: state.pathParameters['id'],
          authRepository: authRepository,
          organizerRepository: organizerRepository,
          paymentRepository: paymentRepository,
        ),
      ),
      GoRoute(
        path: '/organizer/events/:id',
        redirect: (context, state) =>
            _organizerToolsRedirect(authRepository, state),
        builder: (_, state) => OrganizerEventDetailScreen(
          eventId: state.pathParameters['id']!,
          authRepository: authRepository,
          organizerRepository: organizerRepository,
        ),
      ),
      GoRoute(
        path: '/organizer/events/:id/venue',
        redirect: (context, state) =>
            _organizerToolsRedirect(authRepository, state),
        builder: (_, state) => VenueSetupScreen(
          eventId: state.pathParameters['id']!,
          venueRepository: venueCommerceRepository,
        ),
      ),
      GoRoute(
        path: '/organizer/events/:id/venue/table',
        redirect: (context, state) =>
            _organizerToolsRedirect(authRepository, state),
        builder: (_, state) => EditTableScreen(
          eventId: state.pathParameters['id']!,
          venueRepository: venueCommerceRepository,
          table: state.extra is VenueTable ? state.extra as VenueTable : null,
        ),
      ),
      GoRoute(
        path: '/organizer/events/:id/venue/menu',
        redirect: (context, state) =>
            _organizerToolsRedirect(authRepository, state),
        builder: (_, state) => EditMenuItemScreen(
          eventId: state.pathParameters['id']!,
          venueRepository: venueCommerceRepository,
          organizerRepository: organizerRepository,
          item: state.extra is MenuItem ? state.extra as MenuItem : null,
        ),
      ),
      GoRoute(
        path: '/organizer/events/:id/fulfill',
        redirect: (context, state) =>
            _organizerToolsRedirect(authRepository, state),
        builder: (_, state) => VenueFulfillmentScreen(
          eventId: state.pathParameters['id']!,
          organizerRepository: organizerRepository,
          ticketRepository: ticketRepository,
          venueRepository: venueCommerceRepository,
        ),
      ),
      GoRoute(
        path: '/organizer/scan',
        redirect: (context, state) =>
            _organizerToolsRedirect(authRepository, state),
        builder: (_, state) => ScanTicketScreen(
          authRepository: authRepository,
          organizerRepository: organizerRepository,
          ticketRepository: ticketRepository,
          initialEventId: state.extra is String ? state.extra as String : null,
        ),
      ),
      // Must stay after every literal `/organizer/<segment>` route: a dynamic
      // segment declared earlier would match those paths first.
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
            venueCommerceRepository: venueCommerceRepository,
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
      GoRoute(
        path: '/events/:id/tables',
        builder: (_, state) => TablePickerScreen(
          eventId: state.pathParameters['id']!,
          venueRepository: venueCommerceRepository,
          paymentRepository: paymentRepository,
        ),
      ),
      GoRoute(
        path: '/events/:id/menu',
        builder: (_, state) => MenuOrderScreen(
          eventId: state.pathParameters['id']!,
          venueRepository: venueCommerceRepository,
          paymentRepository: paymentRepository,
        ),
      ),
    ],
  );
}
