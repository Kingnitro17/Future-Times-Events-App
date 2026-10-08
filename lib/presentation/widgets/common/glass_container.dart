import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.blur = 16,
    this.width,
    this.height,
    this.color,
    this.borderRadius,
    this.withBorder = true,
    this.elevated = false,
    this.onTap,
    this.gradientOverlay,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double? width;
  final double? height;
  final Color? color;
  final BorderRadius? borderRadius;
  final bool withBorder;
  final bool elevated;
  final VoidCallback? onTap;
  final Gradient? gradientOverlay;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.rXl;
    final content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          margin: margin,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ?? AppColors.glassSurface,
            borderRadius: radius,
            border: withBorder
                ? Border.all(color: AppColors.glassBorder, width: 1)
                : null,
            gradient: gradientOverlay,
            boxShadow: elevated
                ? const [
                    BoxShadow(
                      color: AppColors.glassShadow,
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        borderRadius: radius,
        child: content,
      ),
    );
  }
}
