import 'package:flutter/material.dart';
import '../../utils/breakpoints.dart';

/// Navigation destination for adaptive scaffold
class AdaptiveDestination {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final Widget? screen;

  const AdaptiveDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.screen,
  });
}

/// Adaptive scaffold that switches between different navigation patterns
/// based on screen width
class AdaptiveScaffold extends StatefulWidget {
  final Widget body;
  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  @override
  Widget build(BuildContext context) {
    final breakpoint = context.breakpoint;

    if (breakpoint.isCompact) {
      return _buildCompactLayout(context);
    } else {
      return _buildExpandedLayout(context, breakpoint);
    }
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: widget.body,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
        destinations: widget.destinations
            .map(
              (dest) => NavigationDestination(
                icon: Icon(dest.icon),
                selectedIcon: Icon(dest.selectedIcon ?? dest.icon),
                label: dest.label,
              ),
            )
            .toList(),
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildExpandedLayout(BuildContext context, Breakpoint breakpoint) {
    final isExpanded = breakpoint.isExpandedOrLarger;

    return Scaffold(
      appBar: widget.appBar,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected,
            extended: isExpanded,
            destinations: widget.destinations
                .map(
                  (dest) => NavigationRailDestination(
                    icon: Icon(dest.icon),
                    selectedIcon: Icon(dest.selectedIcon ?? dest.icon),
                    label: Text(dest.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: widget.body,
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
