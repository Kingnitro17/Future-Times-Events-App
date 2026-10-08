import 'package:flutter/material.dart';

import 'glass_container.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) => GlassContainer(
        padding: padding ?? const EdgeInsets.all(16),
        onTap: onTap,
        elevated: elevated,
        borderRadius: BorderRadius.circular(22),
        gradientOverlay: const LinearGradient(
          colors: [Color(0x1FFFFFFF), Color(0x0AFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: child,
      );
}
