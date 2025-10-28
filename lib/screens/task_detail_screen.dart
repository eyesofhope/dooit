import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/recurrence.dart';
import '../providers/task_provider.dart';
import '../utils/app_utils.dart';
import '../widgets/add_edit_task_dialog.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;
  final bool isInDetailPane;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
    this.isInDetailPane = false,
  });

  @override
  Widget build(BuildContext context) {
    // Selector rebuilds detail screen only when the specific task changes.
    return Selector<TaskProvider, Task?>(
      selector: (context, provider) => provider.getTaskById(taskId),
      builder: (context, task, _) {
        if (task == null) {
          if (isInDetailPane) {
            return const Center(
              child: Text('This task no longer exists.'),
            );
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Task Not Found')),
            body: const Center(child: Text('This task no longer exists.')),
          );
        }

        final taskProvider = context.read<TaskProvider>();
        
        if (isInDetailPane) {
          return Column(
            children: [
              _buildDetailPaneAppBar(context, task, taskProvider),
              Expanded(
                child: _buildBody(context, task, taskProvider),
              ),
            ],
          );
        }
        
        return Scaffold(
          appBar: _buildAppBar(context, task, taskProvider),
          body: _buildBody(context, task, taskProvider),
        );
      },
    );
  }

  Widget _buildDetailPaneAppBar(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => taskProvider.clearSelection(),
              ),
              const SizedBox(width: 8),
              const Text(
                'Task Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(context, task),
              ),
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleMenuAction(context, value, task, taskProvider, true),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle_complete',
                    child: ListTile(
                      leading: Icon(
                        task.isCompleted
                            ? Icons.radio_button_unchecked
                            : Icons.check_circle,
                      ),
                      title: Text(
                        task.isCompleted ? 'Mark as Pending' : 'Mark as Complete',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Duplicate'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Delete'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
  ) {
    return AppBar(
      title: const Text('Task Details'),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditDialog(context, task),
        ),
        PopupMenuButton<String>(
          onSelected: (value) =>
              _handleMenuAction(context, value, task, taskProvider, false),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle_complete',
              child: ListTile(
                leading: Icon(
                  task.isCompleted
                      ? Icons.radio_button_unchecked
                      : Icons.check_circle,
                ),
                title: Text(
                  task.isCompleted ? 'Mark as Pending' : 'Mark as Complete',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Duplicate'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTaskCard(context, task),
          const SizedBox(height: 24),
          _buildDetailsSection(context, task),
          const SizedBox(height: 24),
          _buildMetadataSection(context, task),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final priorityColor = AppUtils.getPriorityColor(task.priority);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6)
                                  : null,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            task.isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: task.isCompleted ? Colors.green : null,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            task.isCompleted ? 'Completed' : 'Pending',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: task.isCompleted
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.onSurface
                                            .withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Description',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: task.isCompleted
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, Task task) {
    final priorityColor = AppUtils.getPriorityColor(task.priority);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(context, 'Category', task.category, Icons.category),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              'Priority',
              AppUtils.getPriorityLabel(task.priority),
              Icons.priority_high,
              valueColor: priorityColor,
            ),
            const SizedBox(height: 12),
            if (task.dueDate != null) ...[
              _buildDetailRow(
                context,
                'Due Date',
                AppUtils.formatDateTime(task.dueDate),
                Icons.event,
                valueColor:
                    (!task.isCompleted && AppUtils.isOverdue(task.dueDate))
                    ? Theme.of(context).colorScheme.error
                    : null,
                trailing:
                    (!task.isCompleted && AppUtils.isOverdue(task.dueDate))
                    ? Icon(
                        Icons.warning,
                        color: Theme.of(context).colorScheme.error,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(height: 12),
            ],
            if (_hasRecurrence(task)) ...[
              _buildDetailRow(
                context,
                'Recurrence',
                _recurrenceDescription(task),
                Icons.repeat,
              ),
              const SizedBox(height: 12),
            ],
            _buildDetailRow(
              context,
              'Reminder',
              task.hasNotification && task.dueDate != null
                  ? 'Enabled'
                  : 'Disabled',
              Icons.notifications,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context, Task task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metadata',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              'Created',
              AppUtils.formatDateTime(task.createdAt),
              Icons.add_circle,
            ),
            if (task.completedAt != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                'Completed',
                AppUtils.formatDateTime(task.completedAt),
                Icons.check_circle,
                valueColor: Colors.green,
              ),
            ],
            const SizedBox(height: 12),
            _buildDetailRow(context, 'Task ID', task.id, Icons.fingerprint),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                  fontWeight: valueColor != null ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  bool _hasRecurrence(Task task) {
    final RecurrenceType? type =
        task.recurrenceType ?? task.recurrenceRule?.type;
    return type != null && type != RecurrenceType.none;
  }

  String _recurrenceDescription(Task task) {
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
            due != null ? AppUtils.formatDate(due) : 'the selected date';
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
      description += '\nThis is a recurring instance';
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

  void _showEditDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AddEditTaskDialog(task: task),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    Task task,
    TaskProvider taskProvider,
    bool isInDetailPane,
  ) {
    switch (action) {
      case 'toggle_complete':
        taskProvider.toggleTaskCompletion(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              task.isCompleted
                  ? 'Task marked as pending'
                  : 'Task marked as complete',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'duplicate':
        _duplicateTask(context, task, taskProvider);
        break;
      case 'delete':
        _confirmDeleteTask(context, task, taskProvider, isInDetailPane);
        break;
    }
  }

  void _duplicateTask(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
  ) {
    final duplicatedTask = Task(
      title: '${task.title} (Copy)',
      description: task.description,
      priority: task.priority,
      category: task.category,
      dueDate: task.dueDate,
      hasNotification: task.hasNotification,
      recurrenceType: task.recurrenceType,
      recurrenceInterval: task.recurrenceInterval,
      recurrenceEndDate: task.recurrenceEndDate,
      recurrenceRule: task.recurrenceRule != null
          ? Recurrence(
              type: task.recurrenceRule!.type,
              interval: task.recurrenceRule!.interval,
              endDate: task.recurrenceRule!.endDate,
              weekdays: task.recurrenceRule!.weekdays != null
                  ? List<int>.from(task.recurrenceRule!.weekdays!)
                  : null,
              monthDay: task.recurrenceRule!.monthDay,
              useLastDayOfMonth: task.recurrenceRule!.useLastDayOfMonth,
            )
          : null,
    );

    taskProvider.addTask(duplicatedTask);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task duplicated successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmDeleteTask(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
    bool isInDetailPane,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              taskProvider.deleteTask(task.id);
              Navigator.of(context).pop(); // Close dialog
              
              if (isInDetailPane) {
                taskProvider.clearSelection();
              } else {
                Navigator.of(context).pop(); // Go back to previous screen
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Task "${task.title}" deleted'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
