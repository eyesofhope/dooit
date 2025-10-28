import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/category.dart' as models;
import '../models/app_error.dart';
import '../services/notification_service.dart';
import '../services/logging_service.dart';
import '../utils/app_utils.dart';
import '../utils/error_messages.dart';

class TaskProvider extends ChangeNotifier {
  Box<Task>? _tasksBox;
  Box<models.Category>? _categoriesBox;
  final NotificationService _notificationService = NotificationService();
  final LoggingService _loggingService = LoggingService();

  // State variables
  List<Task> _tasks = [];
  List<models.Category> _categories = [];
  String _searchQuery = '';
  SortOption _currentSort = SortOption.createdDate;
  FilterOption _currentFilter = FilterOption.all;
  String _selectedCategory = 'All';
  AppError? _lastError;

  // Getters
  List<Task> get tasks => _getFilteredAndSortedTasks();
  List<Task> get allTasks => _tasks;
  List<models.Category> get categories => _categories;
  String get searchQuery => _searchQuery;
  SortOption get currentSort => _currentSort;
  FilterOption get currentFilter => _currentFilter;
  String get selectedCategory => _selectedCategory;
  AppError? get lastError => _lastError;

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

  void _setError(AppError error) {
    _lastError = error;
    _loggingService.logAppError(error);
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  Future<void> initialize() async {
    try {
      _loggingService.info('Initializing TaskProvider', context: 'TaskProvider.initialize');
      
      _tasksBox = await Hive.openBox<Task>(AppConstants.tasksBoxName);
      _categoriesBox = await Hive.openBox<models.Category>(
        AppConstants.categoriesBoxName,
      );

      await _loadTasks();
      await _loadCategories();

      if (_categories.isEmpty) {
        await _initializeDefaultCategories();
      }

      await _performDataConsistencyCheck();

      _loggingService.info(
        'TaskProvider initialized with ${_tasks.length} tasks and ${_categories.length} categories',
        context: 'TaskProvider.initialize',
      );
      
      clearError();
    } catch (e, stackTrace) {
      final error = DatabaseError(
        message: ErrorMessages.databaseOpenFailed,
        technicalDetails: e.toString(),
        stackTrace: stackTrace,
        context: 'TaskProvider.initialize',
      );
      _setError(error);
    }
  }

  Future<void> _performDataConsistencyCheck() async {
    try {
      _loggingService.debug('Performing data consistency check', context: 'TaskProvider');
      
      final categoryNames = _categories.map((c) => c.name).toSet();
      bool needsUpdate = false;

      for (var i = 0; i < _tasks.length; i++) {
        final task = _tasks[i];
        if (!categoryNames.contains(task.category)) {
          _loggingService.warning(
            'Task "${task.title}" has invalid category "${task.category}", resetting to default',
            context: 'DataConsistency',
          );
          
          final updatedTask = task.copyWith(category: AppConstants.defaultCategory);
          await _tasksBox?.putAt(i, updatedTask);
          _tasks[i] = updatedTask;
          needsUpdate = true;
        }
      }

      if (needsUpdate) {
        notifyListeners();
        _loggingService.info('Data consistency issues fixed', context: 'DataConsistency');
      }
    } catch (e, stackTrace) {
      _loggingService.warning(
        'Error during data consistency check',
        context: 'DataConsistency',
        error: e,
      );
    }
  }

  Future<void> _loadTasks() async {
    try {
      if (_tasksBox != null) {
        _tasks = _tasksBox!.values.toList();
        _loggingService.debug('Loaded ${_tasks.length} tasks', context: 'TaskProvider._loadTasks');
        notifyListeners();
      }
    } catch (e, stackTrace) {
      final error = DatabaseError(
        message: ErrorMessages.databaseReadFailed,
        technicalDetails: e.toString(),
        stackTrace: stackTrace,
        context: 'TaskProvider._loadTasks',
      );
      _setError(error);
      _tasks = [];
    }
  }

  Future<void> _loadCategories() async {
    try {
      if (_categoriesBox != null) {
        _categories = _categoriesBox!.values.toList();
        _loggingService.debug('Loaded ${_categories.length} categories', context: 'TaskProvider._loadCategories');
        notifyListeners();
      }
    } catch (e, stackTrace) {
      final error = DatabaseError(
        message: ErrorMessages.databaseReadFailed,
        technicalDetails: e.toString(),
        stackTrace: stackTrace,
        context: 'TaskProvider._loadCategories',
      );
      _setError(error);
      _categories = [];
    }
  }

  Future<void> _initializeDefaultCategories() async {
    try {
      final defaultCategories = models.Category.getDefaultCategories();
      for (final category in defaultCategories) {
        await _categoriesBox?.add(category);
      }
      await _loadCategories();
      _loggingService.info('Default categories initialized', context: 'TaskProvider');
    } catch (e, stackTrace) {
      final error = DatabaseError(
        message: ErrorMessages.databaseWriteFailed,
        technicalDetails: e.toString(),
        stackTrace: stackTrace,
        context: 'TaskProvider._initializeDefaultCategories',
      );
      _setError(error);
    }
  }

  Future<bool> addTask(Task task) async {
    try {
      clearError();
      
      if (task.title.trim().isEmpty) {
        throw ValidationError(
          message: ErrorMessages.validationEmptyTitle,
          context: 'TaskProvider.addTask',
        );
      }

      await _tasksBox?.add(task);
      _tasks.add(task);

      if (task.hasNotification && task.dueDate != null && !task.isCompleted) {
        try {
          await _notificationService.scheduleTaskNotification(task);
        } catch (e, stackTrace) {
          _loggingService.warning(
            'Failed to schedule notification for task',
            context: 'TaskProvider.addTask',
            error: e,
          );
        }
      }

      notifyListeners();
      _loggingService.info('Task added: ${task.title}', context: 'TaskProvider.addTask');
      return true;
    } catch (e, stackTrace) {
      final error = e is AppError
          ? e
          : DatabaseError(
              message: ErrorMessages.databaseWriteFailed,
              technicalDetails: e.toString(),
              stackTrace: stackTrace,
              context: 'TaskProvider.addTask',
            );
      _setError(error);
      return false;
    }
  }

  Future<bool> updateTask(Task updatedTask) async {
    try {
      clearError();
      
      if (updatedTask.title.trim().isEmpty) {
        throw ValidationError(
          message: ErrorMessages.validationEmptyTitle,
          context: 'TaskProvider.updateTask',
        );
      }

      final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
      if (index != -1) {
        await _tasksBox?.putAt(index, updatedTask);
        _tasks[index] = updatedTask;

        try {
          await _notificationService.cancelTaskNotification(updatedTask.id);

          if (updatedTask.hasNotification &&
              updatedTask.dueDate != null &&
              !updatedTask.isCompleted) {
            await _notificationService.scheduleTaskNotification(updatedTask);
          }
        } catch (e) {
          _loggingService.warning(
            'Failed to update notification for task',
            context: 'TaskProvider.updateTask',
            error: e,
          );
        }

        notifyListeners();
        _loggingService.info('Task updated: ${updatedTask.title}', context: 'TaskProvider.updateTask');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      final error = e is AppError
          ? e
          : DatabaseError(
              message: ErrorMessages.databaseWriteFailed,
              technicalDetails: e.toString(),
              stackTrace: stackTrace,
              context: 'TaskProvider.updateTask',
            );
      _setError(error);
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      clearError();
      
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        try {
          await _notificationService.cancelTaskNotification(taskId);
        } catch (e) {
          _loggingService.warning(
            'Failed to cancel notification for deleted task',
            context: 'TaskProvider.deleteTask',
            error: e,
          );
        }

        await _tasksBox?.deleteAt(index);
        _tasks.removeAt(index);

        notifyListeners();
        _loggingService.info('Task deleted: $taskId', context: 'TaskProvider.deleteTask');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      final error = DatabaseError(
        message: ErrorMessages.databaseDeleteFailed,
        technicalDetails: e.toString(),
        stackTrace: stackTrace,
        context: 'TaskProvider.deleteTask',
      );
      _setError(error);
      return false;
    }
  }

  Future<bool> toggleTaskCompletion(String taskId) async {
    try {
      clearError();
      
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        final task = _tasks[index];
        final updatedTask = task.copyWith(
          isCompleted: !task.isCompleted,
          completedAt: !task.isCompleted ? DateTime.now() : null,
        );

        return await updateTask(updatedTask);
      }
      return false;
    } catch (e, stackTrace) {
      final error = DatabaseError(
        message: ErrorMessages.databaseWriteFailed,
        technicalDetails: e.toString(),
        stackTrace: stackTrace,
        context: 'TaskProvider.toggleTaskCompletion',
      );
      _setError(error);
      return false;
    }
  }

  Future<bool> addCategory(models.Category category) async {
    try {
      clearError();
      
      if (category.name.trim().isEmpty) {
        throw ValidationError(
          message: ErrorMessages.validationEmptyCategory,
          context: 'TaskProvider.addCategory',
        );
      }

      await _categoriesBox?.add(category);
      _categories.add(category);
      notifyListeners();
      _loggingService.info('Category added: ${category.name}', context: 'TaskProvider.addCategory');
      return true;
    } catch (e, stackTrace) {
      final error = e is AppError
          ? e
          : DatabaseError(
              message: ErrorMessages.databaseWriteFailed,
              technicalDetails: e.toString(),
              stackTrace: stackTrace,
              context: 'TaskProvider.addCategory',
            );
      _setError(error);
      return false;
    }
  }

  Future<bool> updateCategory(models.Category updatedCategory) async {
    try {
      clearError();
      
      final index = _categories.indexWhere(
        (cat) => cat.name == updatedCategory.name,
      );
      if (index != -1) {
        await _categoriesBox?.putAt(index, updatedCategory);
        _categories[index] = updatedCategory;
        notifyListeners();
        _loggingService.info('Category updated: ${updatedCategory.name}', context: 'TaskProvider.updateCategory');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      final error = DatabaseError(
        message: ErrorMessages.databaseWriteFailed,
        technicalDetails: e.toString(),
        stackTrace: stackTrace,
        context: 'TaskProvider.updateCategory',
      );
      _setError(error);
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryName) async {
    try {
      clearError();
      
      final index = _categories.indexWhere((cat) => cat.name == categoryName);
      if (index != -1) {
        final tasksToUpdate = _tasks.where(
          (task) => task.category == categoryName,
        );
        for (final task in tasksToUpdate) {
          final updatedTask = task.copyWith(
            category: AppConstants.defaultCategory,
          );
          await updateTask(updatedTask);
        }

        await _categoriesBox?.deleteAt(index);
        _categories.removeAt(index);

        if (_selectedCategory == categoryName) {
          _selectedCategory = 'All';
        }

        notifyListeners();
        _loggingService.info('Category deleted: $categoryName', context: 'TaskProvider.deleteCategory');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      final error = DatabaseError(
        message: ErrorMessages.databaseDeleteFailed,
        technicalDetails: e.toString(),
        stackTrace: stackTrace,
        context: 'TaskProvider.deleteCategory',
      );
      _setError(error);
      return false;
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

  Future<bool> clearAllData() async {
    try {
      clearError();
      
      await _tasksBox?.clear();
      await _categoriesBox?.clear();
      
      try {
        await _notificationService.cancelAllNotifications();
      } catch (e) {
        _loggingService.warning(
          'Failed to cancel notifications during clear',
          context: 'TaskProvider.clearAllData',
          error: e,
        );
      }

      _tasks.clear();
      _categories.clear();

      await _initializeDefaultCategories();
      notifyListeners();

      _loggingService.info('All data cleared', context: 'TaskProvider.clearAllData');
      return true;
    } catch (e, stackTrace) {
      final error = DatabaseError(
        message: 'Failed to clear data',
        technicalDetails: e.toString(),
        stackTrace: stackTrace,
        context: 'TaskProvider.clearAllData',
      );
      _setError(error);
      return false;
    }
  }

  @override
  void dispose() {
    _tasksBox?.close();
    _categoriesBox?.close();
    super.dispose();
  }
}
