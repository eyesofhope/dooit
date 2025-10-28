import 'package:flutter/material.dart';
import '../../utils/breakpoints.dart';

/// Widget that applies responsive padding based on screen breakpoint
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? customPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.customPadding,
  });

  @override
  Widget build(BuildContext context) {
    if (customPadding != null) {
      return Padding(
        padding: customPadding!,
        child: child,
      );
    }

    final breakpoint = context.breakpoint;
    final horizontalPadding = _getHorizontalPadding(breakpoint);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: child,
    );
  }

  double _getHorizontalPadding(Breakpoint breakpoint) {
    switch (breakpoint) {
      case Breakpoint.compact:
        return 16.0;
      case Breakpoint.medium:
        return 24.0;
      case Breakpoint.expanded:
      case Breakpoint.large:
      case Breakpoint.extraLarge:
        return 32.0;
    }
  }
}

/// Helper function to get responsive padding value
double getResponsivePadding(BuildContext context) {
  final breakpoint = context.breakpoint;
  switch (breakpoint) {
    case Breakpoint.compact:
      return 16.0;
    case Breakpoint.medium:
      return 24.0;
    case Breakpoint.expanded:
    case Breakpoint.large:
    case Breakpoint.extraLarge:
      return 32.0;
  }
}
