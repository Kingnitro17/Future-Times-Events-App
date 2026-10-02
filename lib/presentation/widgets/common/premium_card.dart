import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_elevation.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.onTap,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return AnimatedContainer(
      duration: AppMotion.fast,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rXl,
        boxShadow: elevated ? AppElevation.cardHover : AppElevation.card,
        border: Border.all(color: AppColors.border),
      ),
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              borderRadius: AppRadius.rXl,
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadius.rXl,
                child: content,
              ),
            ),
    );
  }
}
