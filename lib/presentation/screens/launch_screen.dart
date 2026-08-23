import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

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
  late final AnimationController _logoController;
  late final AnimationController _driftController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Single once-only logo animation (900-1200ms)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeInOut),
      ),
    );

    // 2. Gentle slow drifting background motion controller
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _logoController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _proceed();
        }
      });
    });
  }

  void _proceed() {
    final target = widget.showOnboarding ? '/onboarding' : '/';
    context.go(target);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle radial background atmosphere
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.85,
                colors: [
                  AppColors.purple.withValues(alpha: 0.06),
                  AppColors.background,
                ],
              ),
            ),
          ),

          // 4. Subtle Event-Inspired Background Motion Elements (Drifting)
          AnimatedBuilder(
            animation: _driftController,
            builder: (context, _) {
              final val = _driftController.value;
              return Stack(
                children: [
                  Positioned(
                    top: 120 + (val * 12),
                    left: 40 + (val * 8),
                    child: Icon(
                      Icons.confirmation_number_outlined,
                      size: 32,
                      color: AppColors.purple.withValues(alpha: 0.05),
                    ),
                  ),
                  Positioned(
                    top: 180 - (val * 10),
                    right: 50 + (val * 6),
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 36,
                      color: AppColors.pink.withValues(alpha: 0.05),
                    ),
                  ),
                  Positioned(
                    bottom: 220 + (val * 14),
                    left: 60 - (val * 8),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 34,
                      color: AppColors.purple.withValues(alpha: 0.05),
                    ),
                  ),
                  Positioned(
                    bottom: 190 - (val * 12),
                    right: 44 + (val * 10),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      size: 28,
                      color: AppColors.pink.withValues(alpha: 0.05),
                    ),
                  ),
                  Positioned(
                    top: 260 + (val * 16),
                    left: 180 - (val * 10),
                    child: Icon(
                      Icons.circle,
                      size: 14,
                      color: AppColors.purple.withValues(alpha: 0.04),
                    ),
                  ),
                ],
              );
            },
          ),

          // 5. Centered Logo with Once-Only Entrance Animation
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Subtle soft purple glow behind settled logo
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.purple.withValues(
                                          alpha: 0.18 * _glowAnimation.value),
                                      blurRadius: 36,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                              ),

                              // Full branding crest androidlogo.png
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 220,
                                  maxHeight: 120,
                                ),
                                child: Image.asset(
                                  'assets/images/androidlogo.png',
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 6. Bottom Brand + Single Circular Loader
          const Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FUTURE TIMES EVENTS',
                    style: TextStyle(
                      color: AppColors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                  ),
                  SizedBox(height: 14),
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.purple),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
