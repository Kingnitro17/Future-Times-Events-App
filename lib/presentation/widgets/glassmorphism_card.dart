import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A frosted-glass card using BackdropFilter.
/// Ideal for overlays, detail panels, and bottom sheet headers.
class GlassmorphismCard extends StatelessWidget {
  const GlassmorphismCard({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.12,
    this.borderOpacity = 0.3,
    this.borderRadius,
    this.padding,
    this.margin,
    this.color,
  });

  final Widget child;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppTheme.radiusLarge;

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (color ?? AppTheme.electricIndigo).withOpacity(opacity),
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withOpacity(borderOpacity),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
