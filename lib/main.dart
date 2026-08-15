import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/event_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/social_repository.dart';
import 'data/services/payment_service.dart';

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

  // ── Firebase ───────────────────────────────────────────────────────────────
  // Requires google-services.json (Android) / GoogleService-Info.plist (iOS).
  // Run: flutterfire configure
  // await Firebase.initializeApp(); // TEMPORARILY DISABLED FOR UI ONLY MODE

  // ── Dio ────────────────────────────────────────────────────────────────────
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
  DioClient.instance.init();

  // ── Stripe ────────────────────────────────────────────────────────────────
  if (!kIsWeb) {
    PaymentService.init();
  }

  // ── Repositories ──────────────────────────────────────────────────────────
  final eventRepository = EventRepository();
  final authRepository = AuthRepository();
  await authRepository.initialize();
  final socialRepository = SocialRepository();
  final paymentService = PaymentService.instance;

  runApp(EventDistroApp(
    eventRepository: eventRepository,
    authRepository: authRepository,
    socialRepository: socialRepository,
    paymentService: paymentService,
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

class EventDistroApp extends StatelessWidget {
  const EventDistroApp({
    super.key,
    required this.eventRepository,
    required this.authRepository,
    required this.socialRepository,
    required this.paymentService,
  });

  final EventRepository eventRepository;
  final AuthRepository authRepository;
  final SocialRepository socialRepository;
  final PaymentService paymentService;

  @override
  Widget build(BuildContext context) {
    final router = buildAppRouter(
      eventRepository: eventRepository,
      authRepository: authRepository,
      socialRepository: socialRepository,
      paymentService: paymentService,
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
