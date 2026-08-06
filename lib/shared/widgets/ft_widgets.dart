import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Primary gradient button — uses the pink→violet brand gradient.
/// Equivalent to `.btn-primary` / `.btn-grad` on the website.
class FtGradientButton extends StatefulWidget {
  const FtGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 52.0,
    this.gradient,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final LinearGradient? gradient;
  final double? borderRadius;

  @override
  State<FtGradientButton> createState() => _FtGradientButtonState();
}

class _FtGradientButtonState extends State<FtGradientButton>
    with SingleTickerStateMixin {
  late final AnimationController _scale;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _scale;
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => _scale.reverse(),
      onTapUp: disabled ? null : (_) => _scale.forward(),
      onTapCancel: () => _scale.forward(),
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: disabled ? 0.5 : 1.0,
          child: Container(
            height: widget.height,
            width: widget.isFullWidth ? double.infinity : null,
            decoration: BoxDecoration(
              gradient: widget.gradient ?? AppGradients.primary,
              borderRadius: BorderRadius.circular(
                widget.borderRadius ?? AppRadius.lg,
              ),
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.violet.withAlpha(72),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          widget.icon!,
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(widget.label, style: AppTypography.button),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined / ghost button — equivalent to `.btn-outline` on the website.
class FtOutlinedButton extends StatelessWidget {
  const FtOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 52.0,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    label,
                    style: AppTypography.button.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Brand card with glassmorphism styling.
/// Equivalent to `.card` / `.glass-strong` on the website.
class FtCard extends StatelessWidget {
  const FtCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.xxl;
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Material(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: padding ??
                const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Status badge — equivalent to `.badge-*` classes on the website.
class FtBadge extends StatelessWidget {
  const FtBadge({
    super.key,
    required this.label,
    this.variant = FtBadgeVariant.info,
    this.icon,
  });

  final String label;
  final FtBadgeVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      FtBadgeVariant.success => (AppColors.successBg, AppColors.success),
      FtBadgeVariant.warning => (AppColors.warningBg, AppColors.warning),
      FtBadgeVariant.error   => (AppColors.errorBg, AppColors.error),
      FtBadgeVariant.info    => (AppColors.infoBg, AppColors.info),
      FtBadgeVariant.primary => (
        AppColors.violet.withAlpha(26),
        AppColors.violet,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: AppTypography.overline.copyWith(
              color: fg,
              fontSize: 10,
              letterSpacing: 0.04 * 10,
            ),
          ),
        ],
      ),
    );
  }
}

enum FtBadgeVariant { success, warning, error, info, primary }

/// Shimmer skeleton loader — matches `.skeleton` animation on the website.
class FtSkeleton extends StatefulWidget {
  const FtSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final double? borderRadius;

  @override
  State<FtSkeleton> createState() => _FtSkeletonState();
}

class _FtSkeletonState extends State<FtSkeleton>
    with SingleTickerStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? AppRadius.md,
          ),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              AppColors.backgroundTertiary,
              AppColors.backgroundSecondary,
              AppColors.backgroundTertiary,
            ],
            stops: [
              (_controller.value - 0.3).clamp(0.0, 1.0),
              _controller.value.clamp(0.0, 1.0),
              (_controller.value + 0.3).clamp(0.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient text — applies the primary gradient to text.
class FtGradientText extends StatelessWidget {
  const FtGradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient,
  });

  final String text;
  final TextStyle? style;
  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          (gradient ?? AppGradients.primary).createShader(bounds),
      child: Text(text, style: style ?? AppTypography.h2),
    );
  }
}

/// Error state with retry action — used across all screens.
class FtErrorState extends StatelessWidget {
  const FtErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FtOutlinedButton(
                label: 'Try Again',
                onPressed: onRetry,
                isFullWidth: false,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state — used when a list/query returns no results.
class FtEmptyState extends StatelessWidget {
  const FtEmptyState({
    super.key,
    required this.message,
    this.icon,
    this.action,
    this.actionLabel,
  });

  final String message;
  final IconData? icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.inbox_rounded,
              size: 52,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FtGradientButton(
                label: actionLabel!,
                onPressed: action,
                isFullWidth: false,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
