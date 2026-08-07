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
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.charcoalSurface,
    systemNavigationBarIconBrightness: Brightness.light,
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
  AppConfig.validate();
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
      theme: AppTheme.darkTheme,
      routerConfig: router,

      // ── Meta ──────────────────────────────────────────────────────────────
      builder: (context, child) {
        // Clamp font scaling to prevent layout breaks
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler:
                TextScaler.linear(mq.textScaler.scale(1.0).clamp(0.85, 1.2)),
          ),
          child: child!,
        );
      },
    );
  }
}
