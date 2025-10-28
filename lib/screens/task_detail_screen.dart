import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/subtask.dart';
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
          _SubtasksSection(task: task, taskProvider: taskProvider),
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

class _SubtasksSection extends StatefulWidget {
  final Task task;
  final TaskProvider taskProvider;

  const _SubtasksSection({
    required this.task,
    required this.taskProvider,
  });

  @override
  State<_SubtasksSection> createState() => _SubtasksSectionState();
}

class _SubtasksSectionState extends State<_SubtasksSection> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final Map<String, GlobalKey> _subtaskKeys = {};
  String? _errorText;
  String? _pendingScrollToSubtaskId;

  @override
  void dispose() {
    _controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SubtasksSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _controller.clear();
      _errorText = null;
      _pendingScrollToSubtaskId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtasks = widget.task.subtasks;

    for (final subtask in subtasks) {
      _subtaskKeys.putIfAbsent(subtask.id, () => GlobalKey());
    }

    if (_pendingScrollToSubtaskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _subtaskKeys[_pendingScrollToSubtaskId!];
        if (key != null && key.currentContext != null && mounted) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: AppConstants.mediumAnimationDuration,
            curve: Curves.easeOut,
          );
        }
        _pendingScrollToSubtaskId = null;
      });
    }

    final hasIncompleteSubtasks =
        subtasks.any((subtask) => !subtask.isCompleted);
    final hasCompletedSubtasks =
        subtasks.any((subtask) => subtask.isCompleted);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            if (subtasks.isNotEmpty) ...[
              _buildProgressSummary(context),
              const SizedBox(height: 16),
              _buildSubtaskList(subtasks),
            ] else
              _buildEmptyState(context),
            const SizedBox(height: 16),
            _buildAddInput(context),
            if (subtasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasIncompleteSubtasks)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.checklist_rtl),
                      onPressed: _completeAllSubtasks,
                      label: const Text('Complete all subtasks'),
                    ),
                  if (hasCompletedSubtasks)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.clear_all),
                      onPressed: _clearCompletedSubtasks,
                      label: const Text('Clear completed subtasks'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          'Subtasks',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (widget.task.hasSubtasks)
          Text(
            '${widget.task.completedSubtasksCount}/${widget.task.totalSubtasksCount} completed',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressSummary(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = widget.task.subtaskCompletionPercentage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor:
                theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Progress: ${percentage.toStringAsFixed(0)}%',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtaskList(List<Subtask> subtasks) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subtasks.length,
      separatorBuilder: (context, index) => Divider(
        height: 12,
        color: Theme.of(context).dividerColor.withOpacity(0.2),
      ),
      itemBuilder: (context, index) {
        final subtask = subtasks[index];
        final key = _subtaskKeys[subtask.id]!;
        return Dismissible(
          key: ValueKey('subtask_${subtask.id}'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(subtask),
          onDismissed: (_) => _deleteSubtask(subtask, index),
          background: _buildDismissBackground(context),
          child: _buildSubtaskTile(subtask, index, key),
        );
      },
    );
  }

  Widget _buildSubtaskTile(Subtask subtask, int index, GlobalKey key) {
    final theme = Theme.of(context);
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Semantics(
            label: 'Mark ${subtask.title} as complete',
            checked: subtask.isCompleted,
            child: Checkbox(
              value: subtask.isCompleted,
              onChanged: (_) => _toggleSubtask(subtask),
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _editSubtask(subtask),
              child: AnimatedDefaultTextStyle(
                duration: AppConstants.shortAnimationDuration,
                curve: Curves.easeOut,
                style: theme.textTheme.bodyLarge?.copyWith(
                      decoration: subtask.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: subtask.isCompleted
                          ? theme.colorScheme.onSurface.withOpacity(0.6)
                          : theme.colorScheme.onSurface,
                    ) ??
                    TextStyle(
                      fontSize: 16,
                      decoration: subtask.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: subtask.isCompleted
                          ? theme.colorScheme.onSurface.withOpacity(0.6)
                          : theme.colorScheme.onSurface,
                    ),
                child: Text(
                  subtask.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete subtask',
            onPressed: () => _deleteWithConfirmation(subtask, index),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissBackground(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: theme.colorScheme.error.withOpacity(0.9),
      child: Icon(
        Icons.delete_outline,
        color: theme.colorScheme.onError,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'No subtasks yet. Add one to get started.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildAddInput(BuildContext context) {
    return Focus(
      onKey: (node, event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          if (_controller.text.isNotEmpty) {
            setState(() {
              _controller.clear();
              _errorText = null;
            });
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _controller,
        focusNode: _inputFocusNode,
        decoration: InputDecoration(
          hintText: 'Add a subtask...',
          errorText: _errorText,
          prefixIcon: const Icon(Icons.add_outlined),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send),
            tooltip: 'Add subtask',
            onPressed: _addSubtask,
          ),
          counterText: '',
        ),
        onChanged: (_) {
          if (_errorText != null) {
            setState(() {
              _errorText = null;
            });
          }
        },
        onSubmitted: (_) => _addSubtask(),
        textInputAction: TextInputAction.done,
        maxLength: 200,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
      ),
    );
  }

  Future<void> _addSubtask() async {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() {
        _errorText = 'Subtask title cannot be empty';
      });
      return;
    }
    if (title.length > 200) {
      setState(() {
        _errorText = 'Subtask title must be under 200 characters';
      });
      return;
    }

    setState(() {
      _errorText = null;
    });

    final newSubtask =
        await widget.taskProvider.addSubtask(widget.task.id, title);

    if (!mounted) return;

    if (newSubtask != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _controller.clear();
        _pendingScrollToSubtaskId = newSubtask.id;
      });
      _inputFocusNode.requestFocus();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subtask added'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleSubtask(Subtask subtask) async {
    final willComplete = !subtask.isCompleted;
    final updatedTask = await widget.taskProvider
        .toggleSubtaskCompletion(widget.task.id, subtask.id);

    if (!mounted || updatedTask == null) return;

    final allCompleted = updatedTask.hasSubtasks &&
        updatedTask.completedSubtasksCount ==
            updatedTask.totalSubtasksCount;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (willComplete &&
        allCompleted &&
        !widget.taskProvider.autoCompleteTasksWithSubtasks &&
        !updatedTask.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All subtasks completed. Complete task?'),
          action: SnackBarAction(
            label: 'Complete',
            onPressed: () {
              widget.taskProvider.toggleTaskCompletion(updatedTask.id);
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            willComplete
                ? 'Subtask completed'
                : 'Subtask marked as pending',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _editSubtask(Subtask subtask) async {
    final controller = TextEditingController(text: subtask.title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit subtask'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          maxLength: 200,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          decoration: const InputDecoration(
            hintText: 'Subtask title',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted || result == null) return;

    final trimmed = result.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subtask title cannot be empty'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (trimmed == subtask.title) {
      return;
    }

    await widget.taskProvider
        .updateSubtaskTitle(widget.task.id, subtask.id, trimmed);

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subtask updated'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteWithConfirmation(
    Subtask subtask,
    int index,
  ) async {
    final shouldDelete = await _confirmDelete(subtask);
    if (shouldDelete) {
      await _deleteSubtask(subtask, index);
    }
  }

  Future<bool> _confirmDelete(Subtask subtask) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete subtask?'),
        content: Text('Are you sure you want to delete "${subtask.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteSubtask(Subtask subtask, int index) async {
    final result =
        await widget.taskProvider.deleteSubtask(widget.task.id, subtask.id);
    if (!mounted || result == null) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Subtask "${subtask.title}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            widget.taskProvider.restoreSubtask(
              widget.task.id,
              result.subtask,
              atIndex: result.index,
            );
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _completeAllSubtasks() async {
    final shouldProceed = await _confirmBulkAction(
      'Complete all subtasks',
      'Mark all subtasks as completed?',
    );
    if (!shouldProceed) return;

    await widget.taskProvider.completeAllSubtasks(widget.task.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All subtasks marked complete'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearCompletedSubtasks() async {
    final shouldProceed = await _confirmBulkAction(
      'Clear completed subtasks',
      'Remove all completed subtasks?',
    );
    if (!shouldProceed) return;

    await widget.taskProvider.clearCompletedSubtasks(widget.task.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Completed subtasks cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _confirmBulkAction(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
