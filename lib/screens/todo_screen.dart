import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/category.dart' as models;
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
    return AppBar(
      title: _isSearching ? _buildSearchField(context) : _buildAppTitle(context),
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
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'clear_completed',
              child: ListTile(
                leading: Icon(Icons.clear_all),
                title: Text('Clear Completed'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'test_notification',
              child: ListTile(
                leading: Icon(Icons.notifications_active),
                title: Text('Test Notification'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'statistics',
              child: ListTile(
                leading: Icon(Icons.bar_chart),
                title: Text('Statistics'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
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

  Widget _buildAppTitle(BuildContext context) {
    // Selector limits rebuilds to changes in completion stats instead of
    // listening to the entire provider.
    return Selector<TaskProvider, ({int completed, int total})>(
      selector: (context, provider) => (
        completed: provider.completedTasks,
        total: provider.totalTasks,
      ),
      builder: (context, stats, _) {
        return Row(
          children: [
            const Text('DoIt'),
            const Spacer(),
            Text(
              '${stats.completed}/${stats.total}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField(BuildContext context) {
    // Selector keeps the search bar in sync with the provider while avoiding
    // rebuilds from unrelated state changes.
    return Selector<TaskProvider, String>(
      selector: (context, provider) => provider.searchQuery,
      builder: (context, searchQuery, _) {
        if (_searchController.text != searchQuery) {
          _searchController.value = TextEditingValue(
            text: searchQuery,
            selection: TextSelection.collapsed(offset: searchQuery.length),
          );
        }

        return SearchBarWidget(
          controller: _searchController,
          onChanged: (query) =>
              context.read<TaskProvider>().setSearchQuery(query),
          onClear: () {
            _searchController.clear();
            context.read<TaskProvider>().setSearchQuery('');
            setState(() {
              _isSearching = false;
            });
          },
        );
      },
    );
  }

  Widget _buildStatsCard() {
    // Selector rebuilds the stats card only when aggregated metrics change.
    return Selector<TaskProvider,
        ({
          int total,
          int completed,
          int pending,
          int overdue,
          double completion,
        })>(
      selector: (context, provider) => (
        total: provider.totalTasks,
        completed: provider.completedTasks,
        pending: provider.pendingTasks,
        overdue: provider.overdueTasks,
        completion: provider.completionPercentage,
      ),
      builder: (
        context,
        stats,
        _,
      ) {
        if (stats.total == 0) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: StatsCard(
            totalTasks: stats.total,
            completedTasks: stats.completed,
            pendingTasks: stats.pending,
            overdueTasks: stats.overdue,
            completionPercentage: stats.completion,
          ),
        );
      },
    );
  }

  Widget _buildFilterSection() {
    final taskProvider = context.read<TaskProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Selector<TaskProvider, List<models.Category>>(
                  selector: (context, provider) => provider.categories,
                  builder: (context, categories, _) {
                    return Selector<TaskProvider, String>(
                      selector: (context, provider) => provider.selectedCategory,
                      builder: (context, selectedCategory, __) {
                        return FilterChips(
                          categories: categories,
                          selectedCategory: selectedCategory,
                          onCategorySelected: taskProvider.setSelectedCategory,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Selector<TaskProvider, SortOption>(
                selector: (context, provider) => provider.currentSort,
                builder: (context, currentSort, _) {
                  return SortDropdown(
                    currentSort: currentSort,
                    onSortChanged: taskProvider.setSortOption,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Selector<TaskProvider, FilterOption>(
            selector: (context, provider) => provider.currentFilter,
            builder: (context, currentFilter, _) {
              return Row(
                children: [
                  FilterChip(
                    key: const ValueKey('filter_all'),
                    label: const Text('All'),
                    selected: currentFilter == FilterOption.all,
                    onSelected: (_) =>
                        taskProvider.setFilterOption(FilterOption.all),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    key: const ValueKey('filter_pending'),
                    label: const Text('Pending'),
                    selected: currentFilter == FilterOption.pending,
                    onSelected: (_) =>
                        taskProvider.setFilterOption(FilterOption.pending),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    key: const ValueKey('filter_completed'),
                    label: const Text('Completed'),
                    selected: currentFilter == FilterOption.completed,
                    onSelected: (_) =>
                        taskProvider.setFilterOption(FilterOption.completed),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    key: const ValueKey('filter_overdue'),
                    label: const Text('Overdue'),
                    selected: currentFilter == FilterOption.overdue,
                    onSelected: (_) =>
                        taskProvider.setFilterOption(FilterOption.overdue),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    // Selector narrows rebuilds to the filtered task list snapshot.
    return Selector<TaskProvider, List<Task>>(
      selector: (context, provider) => provider.tasks,
      builder: (context, tasks, _) {
        if (tasks.isEmpty) {
          return _buildEmptyState();
        }

        final taskProvider = context.read<TaskProvider>();
        final taskIds = tasks.map((task) => task.id).toList(growable: false);

        return ListView.separated(
          key: const PageStorageKey('todo_tasks_list'),
          padding: const EdgeInsets.all(16.0),
          itemCount: taskIds.length,
          addAutomaticKeepAlives: true,
          cacheExtent: 400,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final taskId = taskIds[index];
            return TaskCard(
              key: ValueKey(taskId),
              taskId: taskId,
              onTap: (task) => _navigateToTaskDetail(context, task),
              onToggleComplete: (task) =>
                  taskProvider.toggleTaskCompletion(task.id),
              onEdit: (task) => _showEditTaskDialog(context, task),
              onDelete: (task) => _confirmDeleteTask(context, task),
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
