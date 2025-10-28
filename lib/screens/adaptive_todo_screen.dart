import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/category.dart' as models;
import '../providers/task_provider.dart';
import '../services/notification_service.dart';
import '../utils/app_utils.dart';
import '../utils/breakpoints.dart';
import '../widgets/task_card.dart';
import '../widgets/add_edit_task_dialog.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chips.dart';
import '../widgets/sort_dropdown.dart';
import '../widgets/stats_card.dart';
import '../widgets/notification_test_widget.dart';
import '../widgets/adaptive/adaptive_scaffold.dart';
import '../widgets/adaptive/master_detail_layout.dart';
import '../widgets/adaptive/responsive_padding.dart';
import 'task_detail_screen.dart';
import 'placeholder_screen.dart';

class AdaptiveTodoScreen extends StatefulWidget {
  const AdaptiveTodoScreen({super.key});

  @override
  State<AdaptiveTodoScreen> createState() => _AdaptiveTodoScreenState();
}

class _AdaptiveTodoScreenState extends State<AdaptiveTodoScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  int _selectedNavIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breakpoint = context.breakpoint;

    return AdaptiveScaffold(
      appBar: _buildAppBar(context),
      destinations: const [
        AdaptiveDestination(
          label: 'Home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
        ),
        AdaptiveDestination(
          label: 'Calendar',
          icon: Icons.calendar_today_outlined,
          selectedIcon: Icons.calendar_today,
        ),
        AdaptiveDestination(
          label: 'Categories',
          icon: Icons.category_outlined,
          selectedIcon: Icons.category,
        ),
        AdaptiveDestination(
          label: 'Settings',
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
        ),
      ],
      selectedIndex: _selectedNavIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedNavIndex = index;
        });
        if (index != 0) {
          _showPlaceholderMessage(context);
          setState(() {
            _selectedNavIndex = 0;
          });
        }
      },
      body: _buildBody(context, breakpoint),
      floatingActionButton: _selectedNavIndex == 0
          ? FloatingActionButton(
              heroTag: "add_task",
              onPressed: () => _showAddTaskDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, Breakpoint breakpoint) {
    if (_selectedNavIndex != 0) {
      return const PlaceholderScreen(
        title: 'Coming Soon',
        message: 'This feature is not yet available.',
      );
    }

    if (breakpoint.isMediumOrLarger) {
      return _buildMasterDetailLayout(context);
    } else {
      return _buildCompactLayout(context);
    }
  }

  Widget _buildMasterDetailLayout(BuildContext context) {
    return Selector<TaskProvider, String?>(
      selector: (context, provider) => provider.selectedTaskId,
      builder: (context, selectedTaskId, _) {
        return MasterDetailLayout(
          master: _buildTaskListContent(context, isInMasterPane: true),
          detail: selectedTaskId != null
              ? TaskDetailScreen(
                  taskId: selectedTaskId,
                  isInDetailPane: true,
                )
              : null,
        );
      },
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return _buildTaskListContent(context, isInMasterPane: false);
  }

  Widget _buildTaskListContent(BuildContext context,
      {required bool isInMasterPane}) {
    return Column(
      children: [
        if (!isInMasterPane) _buildStatsCard(),
        _buildFilterSection(),
        Expanded(child: _buildTaskList(isInMasterPane: isInMasterPane)),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title:
          _isSearching ? _buildSearchField(context) : _buildAppTitle(context),
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
        if (_selectedNavIndex == 0)
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
            ],
          ),
      ],
    );
  }

  Widget _buildAppTitle(BuildContext context) {
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
      builder: (context, stats, _) {
        if (stats.total == 0) {
          return const SizedBox.shrink();
        }

        final padding = getResponsivePadding(context);
        return Padding(
          padding: EdgeInsets.all(padding),
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
    final padding = getResponsivePadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
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

  Widget _buildTaskList({required bool isInMasterPane}) {
    return Selector<TaskProvider, ({List<Task> tasks, String? selectedTaskId})>(
      selector: (context, provider) => (
        tasks: provider.tasks,
        selectedTaskId: provider.selectedTaskId,
      ),
      builder: (context, data, _) {
        if (data.tasks.isEmpty) {
          return _buildEmptyState();
        }

        final taskProvider = context.read<TaskProvider>();
        final taskIds = data.tasks.map((task) => task.id).toList(growable: false);
        final padding = getResponsivePadding(context);

        return ListView.separated(
          key: const PageStorageKey('todo_tasks_list'),
          padding: EdgeInsets.all(padding),
          itemCount: taskIds.length,
          addAutomaticKeepAlives: true,
          cacheExtent: 400,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final taskId = taskIds[index];
            final isSelected = isInMasterPane && taskId == data.selectedTaskId;
            
            return TaskCard(
              key: ValueKey(taskId),
              taskId: taskId,
              isSelected: isSelected,
              onTap: (task) => _handleTaskTap(context, task, isInMasterPane),
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
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 32),
          const NotificationTestWidget(),
        ],
      ),
    );
  }

  void _handleTaskTap(BuildContext context, Task task, bool isInMasterPane) {
    if (isInMasterPane) {
      // In master-detail layout, update selection
      context.read<TaskProvider>().setSelectedTaskId(task.id);
    } else {
      // In compact layout, navigate to full screen
      _navigateToTaskDetail(context, task);
    }
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
    }
  }

  void _clearCompletedTasks(BuildContext context, TaskProvider taskProvider) {
    final completedTasks =
        taskProvider.allTasks.where((task) => task.isCompleted).toList();

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
              ...categoryStats.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text('${entry.value}'),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Text(
                'Pending Tasks by Priority:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...priorityStats.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppUtils.getPriorityLabel(entry.key)),
                      Text('${entry.value}'),
                    ],
                  ),
                );
              }),
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
    NotificationService().showInstantNotification(
      title: 'Test Notification',
      body: 'This is a test notification from DoIt!',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPlaceholderMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming in future phases'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
