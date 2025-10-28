import 'package:flutter/material.dart';
import '../../utils/breakpoints.dart';

/// Widget that creates a responsive grid based on screen breakpoint
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final breakpoint = context.breakpoint;
    final crossAxisCount = _getCrossAxisCount(breakpoint);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  int _getCrossAxisCount(Breakpoint breakpoint) {
    switch (breakpoint) {
      case Breakpoint.compact:
        return 1;
      case Breakpoint.medium:
        return 2;
      case Breakpoint.expanded:
        return 3;
      case Breakpoint.large:
        return 4;
      case Breakpoint.extraLarge:
        return 5;
    }
  }
}
