import 'package:flutter/material.dart';

enum DeviceFormFactor { compact, medium, expanded }

abstract final class ResponsiveUtils {
  static const double compactBreakpoint = 600.0;
  static const double expandedBreakpoint = 840.0;

  static DeviceFormFactor getFormFactor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compactBreakpoint) return DeviceFormFactor.compact;
    if (width < expandedBreakpoint) return DeviceFormFactor.medium;
    return DeviceFormFactor.expanded;
  }

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= compactBreakpoint && width < expandedBreakpoint;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expandedBreakpoint;

  /// Derive event card width for horizontal lists/rails
  static double responsiveCardWidth(double viewportWidth) {
    if (viewportWidth < compactBreakpoint) {
      return (viewportWidth * 0.82).clamp(270.0, 340.0);
    } else if (viewportWidth < expandedBreakpoint) {
      return (viewportWidth * 0.45).clamp(320.0, 380.0);
    } else {
      return 360.0;
    }
  }

  /// Grid cross axis count for large screens / tablets / unfolded foldables
  static int responsiveGridColumns(double viewportWidth) {
    if (viewportWidth < compactBreakpoint) return 1;
    if (viewportWidth < expandedBreakpoint) return 2;
    return 3;
  }

  /// Max readable content width to prevent extreme wide stretching on tablets
  static double maxContentWidth(double viewportWidth) {
    if (viewportWidth >= expandedBreakpoint) return 1040.0;
    if (viewportWidth >= compactBreakpoint) return 760.0;
    return viewportWidth;
  }
}
