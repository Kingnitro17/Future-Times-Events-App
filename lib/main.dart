import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/event_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/social_repository.dart';

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
  final preferences = await SharedPreferences.getInstance();
  final showOnboarding = !(preferences.getBool('onboarding_complete') ?? false);

  runApp(FutureTimesApp(
    eventRepository: eventRepository,
    authRepository: authRepository,
    socialRepository: socialRepository,
    showOnboarding: showOnboarding,
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
                        'Add your Supabase project URL (or project ID) and '
                        'public anonymous key to '
                        'config/app_config.local.json, then restart the app. '
                        'Never use a service-role key in Flutter.',
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

class FutureTimesApp extends StatelessWidget {
  const FutureTimesApp({
    super.key,
    required this.eventRepository,
    required this.authRepository,
    required this.socialRepository,
    required this.showOnboarding,
  });

  final EventRepository eventRepository;
  final AuthRepository authRepository;
  final SocialRepository socialRepository;
  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    final router = buildAppRouter(
      eventRepository: eventRepository,
      authRepository: authRepository,
      socialRepository: socialRepository,
      showOnboarding: showOnboarding,
    );

    return MaterialApp.router(
      title: 'Future Times Events',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,

      // ── Meta ──────────────────────────────────────────────────────────────
      builder: (context, child) {
        return child!;
      },
    );
  }
}
