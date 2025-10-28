import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/category.dart' as models;
import '../services/notification_service.dart';
import '../utils/app_utils.dart';

class TaskProvider extends ChangeNotifier {
  Box<Task>? _tasksBox;
  Box<models.Category>? _categoriesBox;
  final NotificationService _notificationService = NotificationService();

  // State variables
  List<Task> _tasks = [];
  List<models.Category> _categories = [];
  String _searchQuery = '';
  SortOption _currentSort = SortOption.createdDate;
  FilterOption _currentFilter = FilterOption.all;
  String _selectedCategory = 'All';

  // Getters
  List<Task> get tasks => _getFilteredAndSortedTasks();
  List<Task> get allTasks => _tasks;
  List<models.Category> get categories => _categories;
  String get searchQuery => _searchQuery;
  SortOption get currentSort => _currentSort;
  FilterOption get currentFilter => _currentFilter;
  String get selectedCategory => _selectedCategory;

  // Statistics
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((task) => task.isCompleted).length;
  int get pendingTasks => _tasks.where((task) => !task.isCompleted).length;
  int get overdueTasks => _tasks
      .where((task) => !task.isCompleted && AppUtils.isOverdue(task.dueDate))
      .length;

  double get completionPercentage {
    if (_tasks.isEmpty) return 0.0;
    return (completedTasks / totalTasks) * 100;
  }

  // Initialize the provider
  Future<void> initialize() async {
    try {
      _tasksBox = await Hive.openBox<Task>(AppConstants.tasksBoxName);
      _categoriesBox = await Hive.openBox<models.Category>(
        AppConstants.categoriesBoxName,
      );

      // Load existing data
      await _loadTasks();
      await _loadCategories();

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
      _tasks = _tasksBox!.values.toList();
      notifyListeners();
    }
  }

  Future<void> _loadCategories() async {
    if (_categoriesBox != null) {
      _categories = _categoriesBox!.values.toList();
      notifyListeners();
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

  List<Task> _getFilteredAndSortedTasks() {
    developer.Timeline.startSync('TaskProvider._getFilteredAndSortedTasks');
    try {
      List<Task> filteredTasks = List.from(_tasks);

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        filteredTasks = filteredTasks.where((task) {
          return task.title.toLowerCase().contains(_searchQuery) ||
              task.description.toLowerCase().contains(_searchQuery) ||
              task.category.toLowerCase().contains(_searchQuery);
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

  // Clear all data (for testing or reset purposes)
  Future<void> clearAllData() async {
    try {
      await _tasksBox?.clear();
      await _categoriesBox?.clear();
      await _notificationService.cancelAllNotifications();

      _tasks.clear();
      _categories.clear();

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
    super.dispose();
  }
}
