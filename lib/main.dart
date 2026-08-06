import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_config.dart';
import 'core/supabase/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';

Future<void> main() async {
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

  // ── Supabase ───────────────────────────────────────────────────────────────
  await SupabaseService.initialize();

  // ── Determine initial route ─────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_complete') ?? false;

  // ── Auth ───────────────────────────────────────────────────────────────────
  final authRepository = AuthRepository();
  final authBloc = AuthBloc(authRepository)..add(const AuthStarted());

  runApp(FutureTimesApp(
    authBloc: authBloc,
    showOnboarding: !onboardingDone,
  ));
}

class FutureTimesApp extends StatelessWidget {
  const FutureTimesApp({
    super.key,
    required this.authBloc,
    required this.showOnboarding,
  });

  final AuthBloc authBloc;
  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: authBloc,
      child: Builder(
        builder: (context) {
          final router = buildAppRouter(authBloc);

          return MaterialApp.router(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,

            // ── Clamped text scaling ──────────────────────────────────────
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: TextScaler.linear(
                    mq.textScaler.scale(1.0).clamp(0.85, 1.2),
                  ),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
