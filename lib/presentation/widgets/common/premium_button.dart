import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final callback = isLoading || isDisabled ? null : onPressed;
    return AnimatedSwitcher(
      duration: AppMotion.normal,
      child: FilledButton(
        key: ValueKey((isLoading, isDisabled)),
        onPressed: callback,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.purple.withValues(alpha: .45),
          minimumSize: const Size(0, AppSpacing.xxxl),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rLg),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: AppSpacing.lg,
                child: CircularProgressIndicator(
                  strokeWidth: AppSpacing.xs / 2,
                  color: AppColors.surface,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppSpacing.lg),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.foregroundColor = AppColors.purple,
    this.borderColor = AppColors.purple,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor),
          minimumSize: const Size(0, AppSpacing.xxxl),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSpacing.lg),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(label),
          ],
        ),
      );
}

class TextLinkButton extends StatelessWidget {
  const TextLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.purple,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rLg),
          animationDuration: AppMotion.normal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        child: Text(label),
      );
}
