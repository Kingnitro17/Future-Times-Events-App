import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text.dart';
import '../widgets/common/glass_container.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({
    super.key,
    required this.showOnboarding,
  });

  final bool showOnboarding;

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;

  static const List<IconData> _orbitIcons = [
    Icons.music_note_rounded,
    Icons.sports_soccer_rounded,
    Icons.restaurant_rounded,
    Icons.local_bar_rounded,
    Icons.celebration_rounded,
    Icons.photo_camera_rounded,
  ];

  static const List<Color> _orbitColors = [
    AppColors.categoryMusic,
    AppColors.categorySports,
    AppColors.categoryFood,
    AppColors.categoryNightlife,
    AppColors.categoryArts,
    AppColors.categoryOther,
  ];

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _logoController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _logoScale = Tween<double>(begin: 0.9, end: 1.0).chain(
      CurveTween(curve: Curves.easeOutBack),
    ).animate(_logoController);

    _logoController.forward();
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _proceed();
    });
  }

  void _proceed() {
    context.go(widget.showOnboarding ? '/onboarding' : '/');
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orbitRadius = 100.0;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.darkSurface),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _orbitController,
                  builder: (context, _) {
                    final rotation = _orbitController.value * math.pi * 2;
                    return Transform.rotate(
                      angle: rotation,
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: List.generate(_orbitIcons.length, (index) {
                            final angle = (index / _orbitIcons.length) * math.pi * 2;
                            final x = math.cos(angle) * orbitRadius;
                            final y = math.sin(angle) * orbitRadius;
                            return Positioned(
                              left: 120 + x - 22,
                              top: 120 + y - 22,
                              child: GlassContainer(
                                width: 44,
                                height: 44,
                                blur: 18,
                                borderRadius: BorderRadius.circular(22),
                                color: AppColors.glassSurface,
                                child: Center(
                                  child: Icon(
                                    _orbitIcons[index],
                                    size: 20,
                                    color: _orbitColors[index],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, _) => Transform.scale(
                scale: _logoScale.value,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.45),
                        blurRadius: 28,
                        spreadRadius: 2,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/appicon.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.event,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 44,
              child: SafeArea(
                top: false,
                child: Center(
                  child: Text(
                    'FUTURE TIMES EVENTS',
                    textAlign: TextAlign.center,
                    style: AppText.micro.copyWith(
                      color: AppColors.textOnDark,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 42,
                  height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: Color(0x33FFFFFF),
                    color: Color(0xE6FFFFFF),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
