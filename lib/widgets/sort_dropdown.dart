import 'package:flutter/material.dart';
import '../utils/app_utils.dart';

class SortDropdown extends StatelessWidget {
  final SortOption currentSort;
  final ValueChanged<SortOption> onSortChanged;

  const SortDropdown({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      onSelected: onSortChanged,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: SortOption.createdDate,
          child: ListTile(
            leading: Icon(Icons.date_range),
            title: Text('Created Date'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: SortOption.dueDate,
          child: ListTile(
            leading: Icon(Icons.event),
            title: Text('Due Date'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: SortOption.priority,
          child: ListTile(
            leading: Icon(Icons.priority_high),
            title: Text('Priority'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: SortOption.alphabetical,
          child: ListTile(
            leading: Icon(Icons.sort_by_alpha),
            title: Text('Alphabetical'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: SortOption.completionStatus,
          child: ListTile(
            leading: Icon(Icons.check_circle),
            title: Text('Completion'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: SortOption.subtaskProgress,
          child: ListTile(
            leading: Icon(Icons.checklist),
            title: Text('Subtask Progress'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
            Text(
              _getSortLabel(currentSort),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(SortOption sort) {
    switch (sort) {
      case SortOption.createdDate:
        return 'Created';
      case SortOption.dueDate:
        return 'Due Date';
      case SortOption.priority:
        return 'Priority';
      case SortOption.alphabetical:
        return 'A-Z';
      case SortOption.completionStatus:
        return 'Status';
      case SortOption.subtaskProgress:
        return 'Subtasks';
    }
  }
}
