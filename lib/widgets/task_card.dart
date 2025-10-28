import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/recurrence.dart';
import '../providers/task_provider.dart';
import '../utils/app_utils.dart';

/// TaskCard with Selector optimization. It fetches task data by ID and rebuilds
/// only when the specific task changes, preventing unnecessary widget rebuilds
/// when other tasks in the list are modified.
class TaskCard extends StatelessWidget {
  final String taskId;
  final void Function(Task)? onTap;
  final void Function(Task)? onToggleComplete;
  final void Function(Task)? onEdit;
  final void Function(Task)? onDelete;
  final bool isSelected;

  const TaskCard({
    super.key,
    required this.taskId,
    this.onTap,
    this.onToggleComplete,
    this.onEdit,
    this.onDelete,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<TaskProvider, Task?>(
      selector: (context, provider) => provider.getTaskById(taskId),
      shouldRebuild: (previous, next) {
        if (previous == null || next == null) {
          return previous != next;
        }
        return previous.title != next.title ||
            previous.description != next.description ||
            previous.dueDate != next.dueDate ||
            previous.priority != next.priority ||
            previous.category != next.category ||
            previous.isCompleted != next.isCompleted ||
            previous.hasNotification != next.hasNotification ||
            previous.recurrenceType != next.recurrenceType ||
            previous.recurrenceInterval != next.recurrenceInterval ||
            previous.recurrenceEndDate != next.recurrenceEndDate ||
            previous.parentRecurringTaskId != next.parentRecurringTaskId ||
            previous.isRecurringInstance != next.isRecurringInstance ||
            previous.recurrenceRule != next.recurrenceRule;
      },
      builder: (context, task, _) {
        if (task == null) {
          return const SizedBox.shrink();
        }
        return _buildCard(context, task);
      },
    );
  }

  Widget _buildCard(BuildContext context, Task task) {
    final isOverdue = !task.isCompleted && AppUtils.isOverdue(task.dueDate);
    final priorityColor = AppUtils.getPriorityColor(task.priority);

    return Card(
      elevation: isSelected ? 4 : 2,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: InkWell(
        onTap: onTap != null ? () => onTap!(task) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  // Priority indicator
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Task content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task.isCompleted
                                          ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6)
                                          : null,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Completion checkbox
                            Checkbox(
                              value: task.isCompleted,
                              onChanged: (value) =>
                                  onToggleComplete?.call(task),
                              shape: const CircleBorder(),
                            ),
                          ],
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Task metadata
              Row(
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.category,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Priority chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppUtils.getPriorityLabel(task.priority),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: priorityColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_hasRecurrence(task)) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: _recurrenceTooltip(task),
                      child: Icon(
                        Icons.repeat,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Due date or overdue indicator
                  if (task.dueDate != null) ...[
                    Icon(
                      isOverdue ? Icons.warning : Icons.access_time,
                      size: 16,
                      color: isOverdue
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOverdue ? 'Overdue' : AppUtils.formatDate(task.dueDate),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isOverdue
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: isOverdue ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                  // Actions menu
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call(task);
                          break;
                        case 'delete':
                          onDelete?.call(task);
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  bool _hasRecurrence(Task task) {
    final RecurrenceType? type =
        task.recurrenceType ?? task.recurrenceRule?.type;
    return type != null && type != RecurrenceType.none;
  }

  String _recurrenceTooltip(Task task) {
    final RecurrenceType? type =
        task.recurrenceType ?? task.recurrenceRule?.type;
    if (type == null || type == RecurrenceType.none) {
      return 'Does not repeat';
    }

    final int interval =
        task.recurrenceInterval ?? task.recurrenceRule?.interval ?? 1;
    String description;

    switch (type) {
      case RecurrenceType.daily:
        description = interval == 1
            ? 'Every day'
            : 'Every $interval days';
        break;
      case RecurrenceType.weekly:
        final weekdays = task.recurrenceRule?.weekdays ??
            <int>[task.dueDate?.weekday ?? DateTime.monday];
        final labels = (List<int>.from(weekdays)..sort())
            .map(_weekdayLabel)
            .join(', ');
        description = interval == 1
            ? 'Every week on $labels'
            : 'Every $interval weeks on $labels';
        break;
      case RecurrenceType.monthly:
        final bool useLastDay = task.recurrenceRule?.useLastDayOfMonth ??
            (task.dueDate != null && _isLastDay(task.dueDate!));
        final int day =
            task.recurrenceRule?.monthDay ?? task.dueDate?.day ?? 1;
        final String dayLabel = useLastDay ? 'the last day' : 'day $day';
        description = interval == 1
            ? 'Every month on $dayLabel'
            : 'Every $interval months on $dayLabel';
        break;
      case RecurrenceType.yearly:
        final due = task.dueDate;
        final formatted =
            due != null ? AppUtils.formatDate(due) : 'selected date';
        description = interval == 1
            ? 'Every year on $formatted'
            : 'Every $interval years on $formatted';
        break;
      case RecurrenceType.none:
        description = 'Does not repeat';
        break;
    }

    if (task.recurrenceEndDate != null) {
      description += ' until ${AppUtils.formatDate(task.recurrenceEndDate)}';
    }

    if (task.isRecurringInstance) {
      description += '\nRecurring instance';
    }

    return description;
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return 'Day';
    }
  }

  bool _isLastDay(DateTime date) {
    final lastDay = DateTime(date.year, date.month + 1, 0).day;
    return date.day == lastDay;
  }
}
