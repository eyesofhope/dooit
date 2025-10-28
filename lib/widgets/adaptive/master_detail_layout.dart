import 'package:flutter/material.dart';
import '../../utils/breakpoints.dart';

/// Two-pane master-detail layout for medium+ screens
class MasterDetailLayout extends StatelessWidget {
  final Widget master;
  final Widget? detail;
  final Widget? detailPlaceholder;
  final String? selectedItemId;

  const MasterDetailLayout({
    super.key,
    required this.master,
    this.detail,
    this.detailPlaceholder,
    this.selectedItemId,
  });

  @override
  Widget build(BuildContext context) {
    final breakpoint = context.breakpoint;
    final masterWidth = _getMasterWidth(breakpoint);

    return Row(
      children: [
        // Master pane (left)
        SizedBox(
          width: masterWidth,
          child: master,
        ),
        // Divider
        const VerticalDivider(
          width: 1,
          thickness: 1,
        ),
        // Detail pane (right)
        Expanded(
          child: detail ?? _buildDetailPlaceholder(context),
        ),
      ],
    );
  }

  double _getMasterWidth(Breakpoint breakpoint) {
    switch (breakpoint) {
      case Breakpoint.compact:
        return 320.0;
      case Breakpoint.medium:
        return 360.0;
      case Breakpoint.expanded:
        return 400.0;
      case Breakpoint.large:
      case Breakpoint.extraLarge:
        return 480.0;
    }
  }

  Widget _buildDetailPlaceholder(BuildContext context) {
    if (detailPlaceholder != null) {
      return detailPlaceholder!;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a task to view details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
