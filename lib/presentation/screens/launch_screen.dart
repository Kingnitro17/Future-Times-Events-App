import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text.dart';

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
  late final AnimationController _introController;
  late final AnimationController _sparkleController;
  late final AnimationController _brandController;
  late final Animation<double> _logoScale;
  late final Animation<double> _brandOpacity;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: .9, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutBack,
      ),
    );
    _brandController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _brandOpacity = CurvedAnimation(
      parent: _brandController,
      curve: Curves.easeIn,
    );
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _brandController.forward();
    });
    _introController.forward().then((_) {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _proceed();
      });
    });
  }

  void _proceed() {
    context.go(widget.showOnboarding ? '/onboarding' : '/');
  }

  @override
  void dispose() {
    _introController.dispose();
    _sparkleController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.darkSurface),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _sparkleController,
                        builder: (context, _) => CustomPaint(
                          painter: _SparklePainter(_sparkleController.value),
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _introController,
                    builder: (context, _) => Transform.scale(
                      scale: _logoScale.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 196,
                            height: 196,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.purple.withValues(alpha: .4),
                                  AppColors.purple.withValues(alpha: .16),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/appicon.png',
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    top: size.height * .62,
                    child: FadeTransition(
                      opacity: _brandOpacity,
                      child: Text(
                        'FUTURE TIMES EVENTS',
                        textAlign: TextAlign.center,
                        style: AppText.micro.copyWith(
                          color: Colors.white.withValues(alpha: .9),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child: SizedBox(
                          width: 40,
                          height: 2,
                          child: LinearProgressIndicator(
                            backgroundColor: Color(0x33FFFFFF),
                            color: Color(0xE6FFFFFF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.progress);

  final double progress;

  static const _points = <Offset>[
    Offset(.12, .19),
    Offset(.83, .16),
    Offset(.73, .37),
    Offset(.2, .62),
    Offset(.88, .72),
    Offset(.42, .84),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < _points.length; index++) {
      final phase = progress * math.pi * 2 + index * .9;
      final center = Offset(
        _points[index].dx * size.width,
        _points[index].dy * size.height + math.sin(phase) * 5,
      );
      final paint = Paint()
        ..color = Colors.white.withValues(
          alpha: .12 + ((math.sin(phase) + 1) * .07),
        );
      canvas.drawCircle(center, index.isEven ? 2 : 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
