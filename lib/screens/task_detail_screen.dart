import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/app_utils.dart';
import '../widgets/add_edit_task_dialog.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    // Selector rebuilds detail screen only when the specific task changes.
    return Selector<TaskProvider, Task?>(
      selector: (context, provider) => provider.getTaskById(taskId),
      builder: (context, task, _) {
        if (task == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Task Not Found')),
            body: const Center(child: Text('This task no longer exists.')),
          );
        }

        final taskProvider = context.read<TaskProvider>();
        return Scaffold(
          appBar: _buildAppBar(context, task, taskProvider),
          body: _buildBody(context, task, taskProvider),
        );
      },
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
              _handleMenuAction(context, value, task, taskProvider),
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
        _confirmDeleteTask(context, task, taskProvider);
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
              Navigator.of(context).pop(); // Go back to previous screen
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
