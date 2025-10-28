import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/app_settings.dart';
import '../models/category.dart' as models;
import '../services/notification_service.dart';
import '../utils/app_utils.dart';

class TaskProvider extends ChangeNotifier {
  Box<Task>? _tasksBox;
  Box<models.Category>? _categoriesBox;
  Box<AppSettings>? _settingsBox;
  final NotificationService _notificationService = NotificationService();

  // State variables
  List<Task> _tasks = [];
  List<models.Category> _categories = [];
  String _searchQuery = '';
  SortOption _currentSort = SortOption.createdDate;
  FilterOption _currentFilter = FilterOption.all;
  String _selectedCategory = 'All';
  String? _selectedTaskId;
  bool _autoCompleteTasksWithSubtasks = false;
  bool _remindIncompleteSubtasks = false;

  // Getters
  List<Task> get tasks => _getFilteredAndSortedTasks();
  List<Task> get allTasks => _tasks;
  List<models.Category> get categories => _categories;
  String get searchQuery => _searchQuery;
  SortOption get currentSort => _currentSort;
  FilterOption get currentFilter => _currentFilter;
  String get selectedCategory => _selectedCategory;
  String? get selectedTaskId => _selectedTaskId;
  bool get autoCompleteTasksWithSubtasks => _autoCompleteTasksWithSubtasks;
  bool get remindIncompleteSubtasks => _remindIncompleteSubtasks;

  // Statistics
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((task) => task.isCompleted).length;
  int get pendingTasks => _tasks.where((task) => !task.isCompleted).length;
  int get overdueTasks => _tasks
      .where((task) => !task.isCompleted && AppUtils.isOverdue(task.dueDate))
      .length;
  int get tasksWithSubtasks => _tasks.where((task) => task.hasSubtasks).length;
  int get totalSubtasksCount => _tasks.fold<int>(
        0,
        (sum, task) => sum + task.totalSubtasksCount,
      );
  int get completedSubtasksCount => _tasks.fold<int>(
        0,
        (sum, task) => sum + task.completedSubtasksCount,
      );

  double get completionPercentage {
    if (_tasks.isEmpty) return 0.0;
    return (completedTasks / totalTasks) * 100;
  }

  double get overallSubtaskCompletionPercentage {
    if (totalSubtasksCount == 0) return 0.0;
    return (completedSubtasksCount / totalSubtasksCount) * 100;
  }

  // Initialize the provider
  Future<void> initialize() async {
    try {
      _tasksBox = await Hive.openBox<Task>(AppConstants.tasksBoxName);
      _categoriesBox = await Hive.openBox<models.Category>(
        AppConstants.categoriesBoxName,
      );
      _settingsBox = await Hive.openBox<AppSettings>(
        AppConstants.settingsBoxName,
      );

      // Load existing data
      await _loadTasks();
      await _loadCategories();
      await _loadSettings();

      // Initialize default categories if none exist
      if (_categories.isEmpty) {
        await _initializeDefaultCategories();
      }

      debugPrint(
        'TaskProvider initialized with ${_tasks.length} tasks and ${_categories.length} categories',
      );
    } catch (e) {
      debugPrint('Error initializing TaskProvider: $e');
    }
  }

  Future<void> _loadTasks() async {
    if (_tasksBox != null) {
      final tasks = _tasksBox!.values.toList();
      for (var i = 0; i < tasks.length; i++) {
        final task = tasks[i];
        final normalizedSubtasks = _sortedSubtasks(task.subtasks);
        if (!_areSubtaskListsEqual(task.subtasks, normalizedSubtasks)) {
          final updatedTask = task.copyWith(subtasks: normalizedSubtasks);
          await _tasksBox!.putAt(i, updatedTask);
          tasks[i] = updatedTask;
        }
      }
      _tasks = tasks;
      notifyListeners();
    }
  }

  Future<void> _loadCategories() async {
    if (_categoriesBox != null) {
      _categories = _categoriesBox!.values.toList();
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    if (_settingsBox != null && _settingsBox!.isNotEmpty) {
      final settings = _settingsBox!.getAt(0);
      if (settings != null) {
        _autoCompleteTasksWithSubtasks = settings.autoCompleteSubtasks;
        _remindIncompleteSubtasks = settings.remindIncompleteSubtasks;
      }
    }
  }

  Future<void> _initializeDefaultCategories() async {
    final defaultCategories = models.Category.getDefaultCategories();
    for (final category in defaultCategories) {
      await _categoriesBox?.add(category);
    }
    await _loadCategories();
  }

  // Task CRUD operations
  Future<void> addTask(Task task) async {
    try {
      await _tasksBox?.add(task);
      _tasks.add(task);

      // Schedule notification if due date is set and task has notification enabled
      if (task.hasNotification && task.dueDate != null && !task.isCompleted) {
        await _notificationService.scheduleTaskNotification(task);
      }

      notifyListeners();
      debugPrint('Task added: ${task.title}');
    } catch (e) {
      debugPrint('Error adding task: $e');
    }
  }

  Future<void> updateTask(Task updatedTask) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
      if (index != -1) {
        // Update the task in Hive
        await _tasksBox?.putAt(index, updatedTask);
        _tasks[index] = updatedTask;

        // Handle notification updates
        await _notificationService.cancelTaskNotification(updatedTask.id);

        if (updatedTask.hasNotification &&
            updatedTask.dueDate != null &&
            !updatedTask.isCompleted) {
          await _notificationService.scheduleTaskNotification(updatedTask);
        }

        notifyListeners();
        debugPrint('Task updated: ${updatedTask.title}');
      }
    } catch (e) {
      debugPrint('Error updating task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        // Cancel any scheduled notifications
        await _notificationService.cancelTaskNotification(taskId);

        // Remove from storage and local list
        await _tasksBox?.deleteAt(index);
        _tasks.removeAt(index);

        notifyListeners();
        debugPrint('Task deleted: $taskId');
      }
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        final task = _tasks[index];
        final updatedTask = task.copyWith(
          isCompleted: !task.isCompleted,
          completedAt: !task.isCompleted ? DateTime.now() : null,
        );

        await updateTask(updatedTask);
      }
    } catch (e) {
      debugPrint('Error toggling task completion: $e');
    }
  }

  // Subtask operations
  Future<Subtask?> addSubtask(String taskId, String title) async {
    try {
      final trimmedTitle = title.trim();
      if (trimmedTitle.isEmpty) return null;

      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index == -1) return null;

      final task = _tasks[index];
      final nextOrder = task.subtasks.isEmpty
          ? 0
          : task.subtasks.map((subtask) => subtask.order).reduce(math.max) + 1;

      final newSubtask = Subtask(
        title: trimmedTitle,
        order: nextOrder,
      );

      final updatedSubtasks = List<Subtask>.from(task.subtasks)..add(newSubtask);
      final normalized = _sortedSubtasks(updatedSubtasks);
      final updatedTask = _applyParentCompletionState(task, normalized);

      await updateTask(updatedTask);
      return normalized.firstWhere(
        (subtask) => subtask.id == newSubtask.id,
        orElse: () => newSubtask,
      );
    } catch (e) {
      debugPrint('Error adding subtask: $e');
      return null;
    }
  }

  Future<Task?> toggleSubtaskCompletion(String taskId, String subtaskId) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index == -1) return null;

      final task = _tasks[index];
      final updatedSubtasks = task.subtasks.map((subtask) {
        if (subtask.id != subtaskId) return subtask;
        final nowCompleted = !subtask.isCompleted;
        return subtask.copyWith(
          isCompleted: nowCompleted,
          completedAt: nowCompleted ? DateTime.now() : null,
        );
      }).toList();

      final normalized = _sortedSubtasks(updatedSubtasks);
      final updatedTask = _applyParentCompletionState(task, normalized);

      await updateTask(updatedTask);
      return updatedTask;
    } catch (e) {
      debugPrint('Error toggling subtask completion: $e');
      return null;
    }
  }

  Future<Task?> updateSubtaskTitle(
    String taskId,
    String subtaskId,
    String newTitle,
  ) async {
    try {
      final trimmedTitle = newTitle.trim();
      if (trimmedTitle.isEmpty) return null;

      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index == -1) return null;

      final task = _tasks[index];
      final updatedSubtasks = task.subtasks.map((subtask) {
        if (subtask.id == subtaskId) {
          return subtask.copyWith(title: trimmedTitle);
        }
        return subtask;
      }).toList();

      final normalized = _sortedSubtasks(updatedSubtasks);
      final updatedTask = _applyParentCompletionState(task, normalized);

      await updateTask(updatedTask);
      return updatedTask;
    } catch (e) {
      debugPrint('Error updating subtask: $e');
      return null;
    }
  }

  Future<({Subtask subtask, int index})?> deleteSubtask(
    String taskId,
    String subtaskId,
  ) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index == -1) return null;

      final task = _tasks[index];
      final subtaskIndex =
          task.subtasks.indexWhere((item) => item.id == subtaskId);
      if (subtaskIndex == -1) return null;
      final subtask = task.subtasks[subtaskIndex];

      final updatedSubtasks =
          task.subtasks.where((subtask) => subtask.id != subtaskId).toList();
      final normalized = _sortedSubtasks(updatedSubtasks);
      final updatedTask = _applyParentCompletionState(task, normalized);

      await updateTask(updatedTask);
      return (subtask: subtask, index: subtaskIndex);
    } catch (e) {
      debugPrint('Error deleting subtask: $e');
      return null;
    }
  }

  Future<Task?> restoreSubtask(
    String taskId,
    Subtask subtask, {
    int? atIndex,
  }) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index == -1) return null;

      final task = _tasks[index];
      final updatedSubtasks = List<Subtask>.from(task.subtasks);
      final targetIndex = atIndex != null
          ? atIndex < 0
              ? 0
              : atIndex > updatedSubtasks.length
                  ? updatedSubtasks.length
                  : atIndex
          : updatedSubtasks.length;

      final adjustedSubtask = subtask.copyWith(order: targetIndex);
      updatedSubtasks.insert(targetIndex, adjustedSubtask);

      final normalized = _sortedSubtasks(updatedSubtasks);
      final updatedTask = _applyParentCompletionState(task, normalized);

      await updateTask(updatedTask);
      return updatedTask;
    } catch (e) {
      debugPrint('Error restoring subtask: $e');
      return null;
    }
  }

  Future<Task?> reorderSubtasks(
    String taskId,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index == -1) return null;

      final task = _tasks[index];
      if (oldIndex < 0 || oldIndex >= task.subtasks.length) {
        return task;
      }

      var targetIndex = newIndex;
      if (targetIndex > task.subtasks.length) {
        targetIndex = task.subtasks.length;
      }

      final updatedSubtasks = List<Subtask>.from(task.subtasks);
      final subtask = updatedSubtasks.removeAt(oldIndex);
      if (targetIndex > oldIndex) {
        targetIndex -= 1;
      }
      if (targetIndex < 0) {
        targetIndex = 0;
      }
      updatedSubtasks.insert(targetIndex, subtask);

      final normalized = _sortedSubtasks(updatedSubtasks);
      final updatedTask = _applyParentCompletionState(task, normalized);

      await updateTask(updatedTask);
      return updatedTask;
    } catch (e) {
      debugPrint('Error reordering subtasks: $e');
      return null;
    }
  }

  Future<Task?> completeAllSubtasks(String taskId) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index == -1) return null;

      final task = _tasks[index];
      if (task.subtasks.isEmpty) return task;

      final updatedSubtasks = task.subtasks
          .map(
            (subtask) => subtask.copyWith(
              isCompleted: true,
              completedAt: DateTime.now(),
            ),
          )
          .toList();

      final normalized = _sortedSubtasks(updatedSubtasks);
      final updatedTask = _applyParentCompletionState(task, normalized);

      await updateTask(updatedTask);
      return updatedTask;
    } catch (e) {
      debugPrint('Error completing all subtasks: $e');
      return null;
    }
  }

  Future<Task?> clearCompletedSubtasks(String taskId) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index == -1) return null;

      final task = _tasks[index];
      final updatedSubtasks =
          task.subtasks.where((subtask) => !subtask.isCompleted).toList();
      final normalized = _sortedSubtasks(updatedSubtasks);
      final updatedTask = _applyParentCompletionState(task, normalized);

      await updateTask(updatedTask);
      return updatedTask;
    } catch (e) {
      debugPrint('Error clearing completed subtasks: $e');
      return null;
    }
  }

  // Category operations
  Future<void> addCategory(models.Category category) async {
    try {
      await _categoriesBox?.add(category);
      _categories.add(category);
      notifyListeners();
      debugPrint('Category added: ${category.name}');
    } catch (e) {
      debugPrint('Error adding category: $e');
    }
  }

  Future<void> updateCategory(models.Category updatedCategory) async {
    try {
      final index = _categories.indexWhere(
        (cat) => cat.name == updatedCategory.name,
      );
      if (index != -1) {
        await _categoriesBox?.putAt(index, updatedCategory);
        _categories[index] = updatedCategory;
        notifyListeners();
        debugPrint('Category updated: ${updatedCategory.name}');
      }
    } catch (e) {
      debugPrint('Error updating category: $e');
    }
  }

  Future<void> deleteCategory(String categoryName) async {
    try {
      final index = _categories.indexWhere((cat) => cat.name == categoryName);
      if (index != -1) {
        // Update all tasks with this category to 'General'
        final tasksToUpdate = _tasks.where(
          (task) => task.category == categoryName,
        );
        for (final task in tasksToUpdate) {
          final updatedTask = task.copyWith(
            category: AppConstants.defaultCategory,
          );
          await updateTask(updatedTask);
        }

        // Remove the category
        await _categoriesBox?.deleteAt(index);
        _categories.removeAt(index);

        // Reset selected category if it was deleted
        if (_selectedCategory == categoryName) {
          _selectedCategory = 'All';
        }

        notifyListeners();
        debugPrint('Category deleted: $categoryName');
      }
    } catch (e) {
      debugPrint('Error deleting category: $e');
    }
  }

  // Search and filter operations
  void setSearchQuery(String query) {
    developer.Timeline.startSync('TaskProvider.setSearchQuery');
    _searchQuery = query.toLowerCase();
    notifyListeners();
    developer.Timeline.finishSync();
  }

  void setSortOption(SortOption sortOption) {
    developer.Timeline.startSync('TaskProvider.setSortOption');
    _currentSort = sortOption;
    notifyListeners();
    developer.Timeline.finishSync();
  }

  void setFilterOption(FilterOption filterOption) {
    developer.Timeline.startSync('TaskProvider.setFilterOption');
    _currentFilter = filterOption;
    notifyListeners();
    developer.Timeline.finishSync();
  }

  void setSelectedCategory(String category) {
    developer.Timeline.startSync('TaskProvider.setSelectedCategory');
    _selectedCategory = category;
    notifyListeners();
    developer.Timeline.finishSync();
  }

  void setSelectedTaskId(String? taskId) {
    if (_selectedTaskId != taskId) {
      _selectedTaskId = taskId;
      notifyListeners();
    }
  }

  void clearSelection() {
    if (_selectedTaskId != null) {
      _selectedTaskId = null;
      notifyListeners();
    }
  }

  void setAutoCompleteTasksWithSubtasks(bool value) {
    if (_autoCompleteTasksWithSubtasks == value) return;
    _autoCompleteTasksWithSubtasks = value;
    notifyListeners();
  }

  void setRemindIncompleteSubtasks(bool value) {
    if (_remindIncompleteSubtasks == value) return;
    _remindIncompleteSubtasks = value;
    notifyListeners();
  }

  List<Task> _getFilteredAndSortedTasks() {
    developer.Timeline.startSync('TaskProvider._getFilteredAndSortedTasks');
    try {
      List<Task> filteredTasks = List.from(_tasks);

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        filteredTasks = filteredTasks.where((task) {
          return task.title.toLowerCase().contains(_searchQuery) ||
              task.description.toLowerCase().contains(_searchQuery) ||
              task.category.toLowerCase().contains(_searchQuery) ||
              task.subtasks.any(
                (subtask) => subtask.title.toLowerCase().contains(_searchQuery),
              );
        }).toList();
      }

      // Apply category filter
      if (_selectedCategory != 'All') {
        filteredTasks = filteredTasks
            .where((task) => task.category == _selectedCategory)
            .toList();
      }

      // Apply status filter
      filteredTasks = AppUtils.filterTasks(filteredTasks, _currentFilter);

      // Apply sorting
      filteredTasks = AppUtils.sortTasks(filteredTasks, _currentSort);

      return filteredTasks;
    } finally {
      developer.Timeline.finishSync();
    }
  }

  // Utility methods
  Task? getTaskById(String taskId) {
    try {
      return _tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }

  List<Task> getTasksByCategory(String categoryName) {
    return _tasks.where((task) => task.category == categoryName).toList();
  }

  Map<String, int> getCategoryStats() {
    final stats = <String, int>{};
    for (final task in _tasks) {
      stats[task.category] = (stats[task.category] ?? 0) + 1;
    }
    return stats;
  }

  Map<TaskPriority, int> getPriorityStats() {
    final stats = <TaskPriority, int>{};
    for (final task in _tasks.where((t) => !t.isCompleted)) {
      stats[task.priority] = (stats[task.priority] ?? 0) + 1;
    }
    return stats;
  }

  List<Subtask> _sortedSubtasks(List<Subtask> subtasks) {
    final sorted = List<Subtask>.from(subtasks)
      ..sort((a, b) => a.order.compareTo(b.order));
    for (var i = 0; i < sorted.length; i++) {
      if (sorted[i].order != i) {
        sorted[i] = sorted[i].copyWith(order: i);
      }
    }
    return sorted;
  }

  bool _areSubtaskListsEqual(List<Subtask> a, List<Subtask> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].order != b[i].order) {
        return false;
      }
      if (a[i].title != b[i].title || a[i].isCompleted != b[i].isCompleted) {
        return false;
      }
    }
    return true;
  }

  Task _applyParentCompletionState(Task task, List<Subtask> subtasks) {
    final hasSubtasks = subtasks.isNotEmpty;
    final allCompleted = hasSubtasks &&
        subtasks.every((subtask) => subtask.isCompleted);

    var isCompleted = task.isCompleted;
    var completedAt = task.completedAt;

    if (_autoCompleteTasksWithSubtasks) {
      if (allCompleted) {
        if (!task.isCompleted) {
          isCompleted = true;
          completedAt = DateTime.now();
        }
      } else if (task.isCompleted) {
        isCompleted = false;
        completedAt = null;
      }
    }

    return task.copyWith(
      subtasks: subtasks,
      isCompleted: isCompleted,
      completedAt: completedAt,
    );
  }

  // Clear all data (for testing or reset purposes)
  Future<void> clearAllData() async {
    try {
      await _tasksBox?.clear();
      await _categoriesBox?.clear();
      await _settingsBox?.clear();
      await _notificationService.cancelAllNotifications();

      _tasks.clear();
      _categories.clear();
      _autoCompleteTasksWithSubtasks = false;
      _remindIncompleteSubtasks = false;

      await _initializeDefaultCategories();
      notifyListeners();

      debugPrint('All data cleared');
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }

  @override
  void dispose() {
    _tasksBox?.close();
    _categoriesBox?.close();
    _settingsBox?.close();
    super.dispose();
  }
}
