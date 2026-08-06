import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ft_widgets.dart';

const String _kOnboardingCompleteKey = 'onboarding_complete';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      gradient: AppGradients.primary,
      icon: Icons.auto_awesome_rounded,
      headline: 'Discover\nAmazing Events',
      body:
          'Browse concerts, festivals, shows and more happening across Zimbabwe and beyond.',
    ),
    _OnboardingPage(
      gradient: AppGradients.ocean,
      icon: Icons.confirmation_number_rounded,
      headline: 'Book Tickets\nInstantly',
      body:
          'Secure your spot in seconds. Pay with EcoCash and get your QR ticket immediately.',
    ),
    _OnboardingPage(
      gradient: AppGradients.emerald,
      icon: Icons.qr_code_scanner_rounded,
      headline: 'Scan In\nAt The Door',
      body:
          'Show your QR code at the gate for fast, contactless entry. No printing needed.',
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingCompleteKey, true);
    if (mounted) context.go('/home');
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _complete();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Page view ──────────────────────────────────────────────────────
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardingPageView(page: _pages[i]),
          ),

          // ── Skip button ───────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.md,
            right: AppSpacing.lg,
            child: TextButton(
              onPressed: _complete,
              child: Text(
                'Skip',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),

          // ── Bottom Controls ───────────────────────────────────────────────
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
            child: Column(
              children: [
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: i == _currentPage ? 28 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: i == _currentPage ? page.gradient : null,
                        color: i != _currentPage ? AppColors.border : null,
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Primary button
                FtGradientButton(
                  label: _currentPage == _pages.length - 1
                      ? 'Get Started'
                      : 'Continue',
                  gradient: page.gradient,
                  onPressed: _next,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Browse without account
                TextButton(
                  onPressed: _complete,
                  child: Text(
                    'Browse events without an account',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});
  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Column(
      children: [
        // Hero gradient area
        Container(
          height: size.height * 0.52,
          decoration: BoxDecoration(gradient: page.gradient),
          child: Center(
            child: Icon(
              page.icon,
              size: 100,
              color: Colors.white,
            )
                .animate()
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 300.ms),
          ),
        ),

        // Text content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page.headline,
                  style: AppTypography.h1,
                )
                    .animate()
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: AppSpacing.md),
                Text(
                  page.body,
                  style: AppTypography.body,
                )
                    .animate()
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: 500.ms,
                      delay: 100.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .fadeIn(duration: 400.ms, delay: 100.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.gradient,
    required this.icon,
    required this.headline,
    required this.body,
  });
  final LinearGradient gradient;
  final IconData icon;
  final String headline;
  final String body;
}
