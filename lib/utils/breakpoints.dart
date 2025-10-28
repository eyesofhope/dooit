import 'package:flutter/material.dart';

/// Material Design 3 breakpoint definitions
enum Breakpoint {
  /// 0-599px: Phone portrait
  compact,
  
  /// 600-839px: Tablet portrait, phone landscape
  medium,
  
  /// 840-1199px: Tablet landscape, small desktop
  expanded,
  
  /// 1200-1599px: Desktop
  large,
  
  /// 1600px+: Large desktop
  extraLarge;

  /// Get breakpoint from width
  static Breakpoint fromWidth(double width) {
    if (width < 600) {
      return Breakpoint.compact;
    } else if (width < 840) {
      return Breakpoint.medium;
    } else if (width < 1200) {
      return Breakpoint.expanded;
    } else if (width < 1600) {
      return Breakpoint.large;
    } else {
      return Breakpoint.extraLarge;
    }
  }

  /// Check if breakpoint is compact
  bool get isCompact => this == Breakpoint.compact;

  /// Check if breakpoint is medium or larger
  bool get isMediumOrLarger => index >= Breakpoint.medium.index;

  /// Check if breakpoint is expanded or larger
  bool get isExpandedOrLarger => index >= Breakpoint.expanded.index;

  /// Check if breakpoint is large or larger
  bool get isLargeOrLarger => index >= Breakpoint.large.index;
}

/// Extension on BuildContext to easily access current breakpoint
extension BreakpointExtension on BuildContext {
  /// Get current breakpoint based on screen width
  Breakpoint get breakpoint {
    final width = MediaQuery.sizeOf(this).width;
    return Breakpoint.fromWidth(width);
  }
}
