import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';
import '../utils/app_utils.dart';
import '../widgets/task_card.dart';
import '../widgets/add_edit_task_dialog.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chips.dart';
import '../widgets/sort_dropdown.dart';
import '../widgets/stats_card.dart';
import '../widgets/notification_test_widget.dart';
import 'task_detail_screen.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildStatsCard(),
          _buildFilterSection(),
          Expanded(child: _buildTaskList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "add_task",
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return AppBar(
      title: _isSearching
          ? SearchBarWidget(
              controller: _searchController,
              onChanged: (query) => taskProvider.setSearchQuery(query),
              onClear: () {
                _searchController.clear();
                taskProvider.setSearchQuery('');
                setState(() {
                  _isSearching = false;
                });
              },
            )
          : Row(
              children: [
                const Text('DoIt'),
                const Spacer(),
                Text(
                  '${taskProvider.completedTasks}/${taskProvider.totalTasks}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear_completed',
              child: ListTile(
                leading: Icon(Icons.clear_all),
                title: Text('Clear Completed'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'test_notification',
              child: ListTile(
                leading: Icon(Icons.notifications_active),
                title: Text('Test Notification'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'statistics',
              child: ListTile(
                leading: Icon(Icons.bar_chart),
                title: Text('Statistics'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (taskProvider.totalTasks == 0) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: StatsCard(
            totalTasks: taskProvider.totalTasks,
            completedTasks: taskProvider.completedTasks,
            pendingTasks: taskProvider.pendingTasks,
            overdueTasks: taskProvider.overdueTasks,
            completionPercentage: taskProvider.completionPercentage,
          ),
        );
      },
    );
  }

  Widget _buildFilterSection() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilterChips(
                      categories: taskProvider.categories,
                      selectedCategory: taskProvider.selectedCategory,
                      onCategorySelected: taskProvider.setSelectedCategory,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SortDropdown(
                    currentSort: taskProvider.currentSort,
                    onSortChanged: taskProvider.setSortOption,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: taskProvider.currentFilter == FilterOption.all,
                    onSelected: (selected) =>
                        taskProvider.setFilterOption(FilterOption.all),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Pending'),
                    selected:
                        taskProvider.currentFilter == FilterOption.pending,
                    onSelected: (selected) =>
                        taskProvider.setFilterOption(FilterOption.pending),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Completed'),
                    selected:
                        taskProvider.currentFilter == FilterOption.completed,
                    onSelected: (selected) =>
                        taskProvider.setFilterOption(FilterOption.completed),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Overdue'),
                    selected:
                        taskProvider.currentFilter == FilterOption.overdue,
                    onSelected: (selected) =>
                        taskProvider.setFilterOption(FilterOption.overdue),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskList() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.tasks;

        if (tasks.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TaskCard(
              task: task,
              onTap: () => _navigateToTaskDetail(context, task),
              onToggleComplete: () =>
                  taskProvider.toggleTaskCompletion(task.id),
              onEdit: () => _showEditTaskDialog(context, task),
              onDelete: () => _confirmDeleteTask(context, task),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.task_alt,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first task',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          // Add notification test widget for empty state
          const NotificationTestWidget(),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddEditTaskDialog(),
    );
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AddEditTaskDialog(task: task),
    );
  }

  void _navigateToTaskDetail(BuildContext context, Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(taskId: task.id),
      ),
    );
  }

  void _confirmDeleteTask(BuildContext context, Task task) {
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
              Provider.of<TaskProvider>(
                context,
                listen: false,
              ).deleteTask(task.id);
              Navigator.of(context).pop();
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

  void _handleMenuAction(BuildContext context, String action) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    switch (action) {
      case 'clear_completed':
        _clearCompletedTasks(context, taskProvider);
        break;
      case 'test_notification':
        _testNotification(context);
        break;
      case 'statistics':
        _showStatistics(context, taskProvider);
        break;
      case 'settings':
        _showSettings(context);
        break;
    }
  }

  void _clearCompletedTasks(BuildContext context, TaskProvider taskProvider) {
    final completedTasks = taskProvider.allTasks
        .where((task) => task.isCompleted)
        .toList();

    if (completedTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No completed tasks to clear'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Completed Tasks'),
        content: Text(
          'Are you sure you want to delete ${completedTasks.length} completed tasks?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              for (final task in completedTasks) {
                taskProvider.deleteTask(task.id);
              }
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${completedTasks.length} completed tasks cleared',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showStatistics(BuildContext context, TaskProvider taskProvider) {
    final categoryStats = taskProvider.getCategoryStats();
    final priorityStats = taskProvider.getPriorityStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistics'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tasks by Category:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...categoryStats.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(entry.key), Text('${entry.value}')],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pending Tasks by Priority:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...priorityStats.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppUtils.getPriorityLabel(entry.key)),
                      Text('${entry.value}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _testNotification(BuildContext context) {
    NotificationService().scheduleTestNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification scheduled for 5 seconds from now!'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    // Placeholder for settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
