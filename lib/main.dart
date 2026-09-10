import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/event_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/social_repository.dart';
import 'data/repositories/saved_events_repository.dart';
import 'data/repositories/discovery_preferences_repository.dart';
import 'data/repositories/ticket_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/services/realtime_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── System UI ──────────────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    AppConfig.validate();
  } on StateError {
    runApp(const _ConfigurationErrorApp());
    return;
  }
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
    authOptions:
        const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );

  // ── Repositories ──────────────────────────────────────────────────────────
  final eventRepository = EventRepository();
  final authRepository = AuthRepository();
  await authRepository.initialize();
  final socialRepository = SocialRepository();
  final savedEventsRepository =
      SavedEventsRepository(authRepository: authRepository);
  final ticketRepository = TicketRepository(authRepository: authRepository);
  final notificationRepository = NotificationRepository();

  if (authRepository.isSignedIn) {
    await savedEventsRepository.load();
    await notificationRepository.fetchNotifications();
  }

  // Centralized Supabase Realtime Service
  RealtimeService(
    authRepository: authRepository,
    savedEventsRepository: savedEventsRepository,
    socialRepository: socialRepository,
    ticketRepository: ticketRepository,
    notificationRepository: notificationRepository,
  );

  final discoveryPreferences = await DiscoveryPreferencesRepository.create();
  final preferences = await SharedPreferences.getInstance();
  final showOnboarding =
      !(preferences.getBool(DiscoveryPreferencesRepository.completionKey) ??
          false);

  runApp(FutureTimesApp(
    eventRepository: eventRepository,
    authRepository: authRepository,
    socialRepository: socialRepository,
    showOnboarding: showOnboarding,
    savedEventsRepository: savedEventsRepository,
    discoveryPreferences: discoveryPreferences,
    notificationRepository: notificationRepository,
  ));
}

class _ConfigurationErrorApp extends StatelessWidget {
  const _ConfigurationErrorApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Future Times Events',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      const Icon(Icons.settings_outlined,
                          size: 64, color: AppTheme.electricIndigo),
                      const SizedBox(height: 20),
                      Text('Local configuration needed',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      const Text(
                        'Your local Supabase values were not passed to Flutter. '
                        'Start Chrome with tools/run_chrome.ps1 or Android with '
                        'tools/run_android.ps1. Both safely read '
                        'config/app_config.local.json. Never use a '
                        'service-role key in Flutter.',
                        textAlign: TextAlign.center,
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

class FutureTimesApp extends StatefulWidget {
  const FutureTimesApp({
    super.key,
    required this.eventRepository,
    required this.authRepository,
    required this.socialRepository,
    required this.showOnboarding,
    required this.savedEventsRepository,
    required this.discoveryPreferences,
    required this.notificationRepository,
  });

  final EventRepository eventRepository;
  final AuthRepository authRepository;
  final SocialRepository socialRepository;
  final bool showOnboarding;
  final SavedEventsRepository savedEventsRepository;
  final DiscoveryPreferencesRepository discoveryPreferences;
  final NotificationRepository notificationRepository;

  @override
  State<FutureTimesApp> createState() => _FutureTimesAppState();
}

class _FutureTimesAppState extends State<FutureTimesApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildAppRouter(
      eventRepository: widget.eventRepository,
      authRepository: widget.authRepository,
      socialRepository: widget.socialRepository,
      showOnboarding: widget.showOnboarding,
      savedEventsRepository: widget.savedEventsRepository,
      discoveryPreferences: widget.discoveryPreferences,
      notificationRepository: widget.notificationRepository,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Future Times Events',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
