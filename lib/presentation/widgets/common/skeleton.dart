import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_elevation.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = AppSpacing.lg,
    this.radius = AppRadius.md,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppColors.surfaceMuted,
        highlightColor: AppColors.surface,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );
}

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) => SkeletonBox(
        width: width,
        height: AppSpacing.md,
        radius: AppRadius.xs,
      );
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: AppSpacing.card,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.rXl,
          boxShadow: AppElevation.card,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: AppSpacing.xxxl),
            SizedBox(height: AppSpacing.md),
            SkeletonLine(width: AppSpacing.xxxl * 3),
            SizedBox(height: AppSpacing.sm),
            SkeletonLine(),
          ],
        ),
      );
}
