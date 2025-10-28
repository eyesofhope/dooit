import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/category.dart' as models;
import '../services/notification_service.dart';
import '../utils/app_utils.dart';

class CategoryOperationException implements Exception {
  CategoryOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CategoryStats {
  const CategoryStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
  });

  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;

  double get completionPercentage =>
      totalTasks == 0 ? 0 : (completedTasks / totalTasks) * 100;
}

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
  String _selectedCategory = AppConstants.systemCategoryAll;
  String? _selectedTaskId;

  // Getters
  List<Task> get tasks => _getFilteredAndSortedTasks();
  List<Task> get allTasks => _tasks;
  List<models.Category> get categories => List.unmodifiable(_categories);
  bool get hasUncategorizedTasks => _tasks.any(_isTaskUncategorized);
  String get searchQuery => _searchQuery;
  SortOption get currentSort => _currentSort;
  FilterOption get currentFilter => _currentFilter;
  String get selectedCategory => _selectedCategory;
  String? get selectedTaskId => _selectedTaskId;

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
      _categories = _categoriesBox!.values.map((category) {
        category.name = _sanitizeCategoryLabel(category.name);
        return category;
      }).toList();
      _ensureSelectedCategoryIsValid();
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
  bool categoryExists(String name, {String? excludeName}) {
    return _categoryExists(name, excludeName: excludeName);
  }

  Future<void> addCategory(models.Category category) async {
    final sanitizedName = _sanitizeCategoryLabel(category.name);

    if (sanitizedName.isEmpty) {
      throw CategoryOperationException('Category name cannot be empty.');
    }
    if (sanitizedName.length > AppConstants.maxCategoryNameLength) {
      throw CategoryOperationException(
        'Category name must be ${AppConstants.maxCategoryNameLength} characters or fewer.',
      );
    }
    if (_isReservedCategory(sanitizedName)) {
      throw CategoryOperationException(
        'This name is reserved. Please choose a different name.',
      );
    }
    if (_categoryExists(sanitizedName)) {
      throw CategoryOperationException('A category with this name already exists.');
    }

    final newCategory = models.Category(
      name: sanitizedName,
      colorValue: category.colorValue,
    );

    try {
      await _categoriesBox?.add(newCategory);
      _categories.add(newCategory);
      notifyListeners();
      debugPrint('Category added: $sanitizedName');
    } catch (e) {
      debugPrint('Error adding category: $e');
      throw CategoryOperationException('Failed to add category. Please try again.');
    }
  }

  Future<void> updateCategory(
    String existingName,
    models.Category updatedCategory,
  ) async {
    final sanitizedExistingName = _sanitizeCategoryLabel(existingName);
    final sanitizedNewName = _sanitizeCategoryLabel(updatedCategory.name);

    if (sanitizedNewName.isEmpty) {
      throw CategoryOperationException('Category name cannot be empty.');
    }
    if (sanitizedNewName.length > AppConstants.maxCategoryNameLength) {
      throw CategoryOperationException(
        'Category name must be ${AppConstants.maxCategoryNameLength} characters or fewer.',
      );
    }
    if (_isReservedCategory(sanitizedNewName)) {
      throw CategoryOperationException(
        'This name is reserved. Please choose a different name.',
      );
    }
    if (_isReservedCategory(sanitizedExistingName)) {
      throw CategoryOperationException('System categories cannot be modified.');
    }

    final categoryIndex = _categories.indexWhere(
      (category) =>
          _normalizeCategoryName(category.name) ==
          _normalizeCategoryName(sanitizedExistingName),
    );

    if (categoryIndex == -1) {
      throw CategoryOperationException('Category not found.');
    }

    if (_categoryExists(sanitizedNewName, excludeName: sanitizedExistingName)) {
      throw CategoryOperationException('A category with this name already exists.');
    }

    final originalCategory = _categories[categoryIndex];
    final hasNameChanged =
        _normalizeCategoryName(originalCategory.name) !=
        _normalizeCategoryName(sanitizedNewName);

    final replacement = originalCategory.copyWith(
      name: sanitizedNewName,
      colorValue: updatedCategory.colorValue,
    );

    try {
      await _categoriesBox?.putAt(categoryIndex, replacement);
      _categories[categoryIndex] = replacement;

      if (hasNameChanged) {
        await _renameCategoryAssignments(
          sanitizedExistingName,
          sanitizedNewName,
        );
      } else {
        _ensureSelectedCategoryIsValid();
      }

      notifyListeners();
      debugPrint('Category updated: $sanitizedNewName');
    } catch (e) {
      debugPrint('Error updating category: $e');
      throw CategoryOperationException('Failed to update category. Please try again.');
    }
  }

  Future<int> deleteCategory(
    String categoryName, {
    String? replacementName,
  }) async {
    final sanitizedName = _sanitizeCategoryLabel(categoryName);

    if (_isReservedCategory(sanitizedName)) {
      throw CategoryOperationException('System categories cannot be deleted.');
    }

    if (_categories.length <= 1) {
      throw CategoryOperationException('At least one category must remain.');
    }

    final categoryIndex = _categories.indexWhere(
      (category) =>
          _normalizeCategoryName(category.name) ==
          _normalizeCategoryName(sanitizedName),
    );

    if (categoryIndex == -1) {
      throw CategoryOperationException('Category not found.');
    }

    final normalizedReplacement = replacementName == null
        ? null
        : _sanitizeCategoryLabel(replacementName);

    if (normalizedReplacement != null &&
        _normalizeCategoryName(normalizedReplacement) ==
            _normalizeCategoryName(AppConstants.systemCategoryAll)) {
      throw CategoryOperationException('Tasks cannot be reassigned to the All category.');
    }

    if (normalizedReplacement != null &&
        !_isReservedCategory(normalizedReplacement) &&
        !_categoryExists(normalizedReplacement)) {
      throw CategoryOperationException('Replacement category was not found.');
    }

    final taskIndexesToUpdate = <int>[];

    for (var i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      if (_taskBelongsToCategory(task, sanitizedName)) {
        taskIndexesToUpdate.add(i);
      }
    }

    final targetCategory =
        normalizedReplacement ?? AppConstants.uncategorizedCategory;

    try {
      for (final taskIndex in taskIndexesToUpdate) {
        final task = _tasks[taskIndex];
        final updatedTask = task.copyWith(category: targetCategory);
        await _tasksBox?.putAt(taskIndex, updatedTask);
        _tasks[taskIndex] = updatedTask;
      }

      await _categoriesBox?.deleteAt(categoryIndex);
      _categories.removeAt(categoryIndex);

      if (_normalizeCategoryName(_selectedCategory) ==
          _normalizeCategoryName(sanitizedName)) {
        _selectedCategory =
            normalizedReplacement ?? AppConstants.systemCategoryAll;
      }

      _ensureSelectedCategoryIsValid();
      notifyListeners();

      debugPrint(
        'Category deleted: $sanitizedName, ${taskIndexesToUpdate.length} tasks updated',
      );
      return taskIndexesToUpdate.length;
    } catch (e) {
      debugPrint('Error deleting category: $e');
      throw CategoryOperationException('Failed to delete category. Please try again.');
    }
  }

  Future<void> reorderCategories(List<models.Category> newOrder) async {
    if (newOrder.length != _categories.length) {
      throw CategoryOperationException('Reorder operation is inconsistent.');
    }

    try {
      _categories
        ..clear()
        ..addAll(newOrder.map((category) {
          category.name = _sanitizeCategoryLabel(category.name);
          return category;
        }));

      if (_categoriesBox != null) {
        await _categoriesBox!.clear();
        for (final category in _categories) {
          await _categoriesBox!.add(category);
        }
      }

      notifyListeners();
      debugPrint('Categories reordered');
    } catch (e) {
      debugPrint('Error reordering categories: $e');
      throw CategoryOperationException('Failed to reorder categories. Please try again.');
    }
  }

  CategoryStats getCategoryStats(String categoryName) {
    final tasksForCategory = _tasks
        .where((task) => _taskBelongsToCategory(task, categoryName))
        .toList();

    final total = tasksForCategory.length;
    final completed = tasksForCategory.where((task) => task.isCompleted).length;
    final pending = total - completed;
    final overdue = tasksForCategory
        .where((task) => !task.isCompleted && AppUtils.isOverdue(task.dueDate))
        .length;

    return CategoryStats(
      totalTasks: total,
      completedTasks: completed,
      pendingTasks: pending,
      overdueTasks: overdue,
    );
  }

  List<Task> getTasksByCategory(String categoryName) {
    return _tasks
        .where((task) => _taskBelongsToCategory(task, categoryName))
        .toList();
  }

  List<Task> getTasksPreviewByCategory(
    String categoryName, {
    int limit = 5,
  }) {
    return getTasksByCategory(categoryName).take(limit).toList();
  }

  Future<int> completeAllTasksInCategory(String categoryName) async {
    final tasksToComplete = getTasksByCategory(categoryName)
        .where((task) => !task.isCompleted)
        .toList();

    for (final task in tasksToComplete) {
      final updatedTask = task.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      await updateTask(updatedTask);
    }

    return tasksToComplete.length;
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

    final sanitized = _sanitizeCategoryLabel(category);
    final normalized = _normalizeCategoryName(sanitized);
    String nextSelection;

    if (normalized ==
        _normalizeCategoryName(AppConstants.systemCategoryAll)) {
      nextSelection = AppConstants.systemCategoryAll;
    } else if (normalized ==
        _normalizeCategoryName(AppConstants.uncategorizedCategory)) {
      nextSelection = AppConstants.uncategorizedCategory;
    } else if (_categoryExists(sanitized)) {
      nextSelection = sanitized;
    } else {
      nextSelection = AppConstants.systemCategoryAll;
    }

    if (_normalizeCategoryName(_selectedCategory) ==
        _normalizeCategoryName(nextSelection)) {
      developer.Timeline.finishSync();
      return;
    }

    _selectedCategory = nextSelection;
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
      if (_normalizeCategoryName(_selectedCategory) !=
          _normalizeCategoryName(AppConstants.systemCategoryAll)) {
        filteredTasks = filteredTasks
            .where((task) => _taskBelongsToCategory(task, _selectedCategory))
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

  String _sanitizeCategoryLabel(String name) => name.trim();

  String _normalizeCategoryName(String? name) {
    return name == null ? '' : name.trim().toLowerCase();
  }

  bool _isReservedCategory(String name) {
    final normalized = _normalizeCategoryName(name);
    for (final reserved in AppConstants.reservedCategoryNames) {
      if (_normalizeCategoryName(reserved) == normalized) {
        return true;
      }
    }
    return false;
  }

  bool _categoryExists(String name, {String? excludeName}) {
    final normalized = _normalizeCategoryName(name);
    final normalizedExclude =
        excludeName == null ? null : _normalizeCategoryName(excludeName);

    return _categories.any((category) {
      final categoryName = _normalizeCategoryName(category.name);
      if (normalizedExclude != null && categoryName == normalizedExclude) {
        return false;
      }
      return categoryName == normalized;
    });
  }

  bool _isTaskUncategorized(Task task) {
    final normalized = _normalizeCategoryName(task.category);
    return normalized.isEmpty ||
        normalized == _normalizeCategoryName(AppConstants.uncategorizedCategory);
  }

  bool _taskBelongsToCategory(Task task, String categoryName) {
    final normalizedCategory = _normalizeCategoryName(categoryName);

    if (normalizedCategory ==
        _normalizeCategoryName(AppConstants.systemCategoryAll)) {
      return true;
    }

    if (normalizedCategory ==
        _normalizeCategoryName(AppConstants.uncategorizedCategory)) {
      return _isTaskUncategorized(task);
    }

    return _normalizeCategoryName(task.category) == normalizedCategory;
  }

  Future<void> _renameCategoryAssignments(String from, String to) async {
    final normalizedFrom = _normalizeCategoryName(from);
    final sanitizedTo = _sanitizeCategoryLabel(to);

    for (var i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      if (_normalizeCategoryName(task.category) == normalizedFrom) {
        final updatedTask = task.copyWith(category: sanitizedTo);
        await _tasksBox?.putAt(i, updatedTask);
        _tasks[i] = updatedTask;
      }
    }

    if (_normalizeCategoryName(_selectedCategory) == normalizedFrom) {
      _selectedCategory = sanitizedTo;
    }

    _ensureSelectedCategoryIsValid();
  }

  void _ensureSelectedCategoryIsValid() {
    final normalizedSelection = _normalizeCategoryName(_selectedCategory);

    if (normalizedSelection ==
        _normalizeCategoryName(AppConstants.systemCategoryAll)) {
      return;
    }

    if (normalizedSelection ==
        _normalizeCategoryName(AppConstants.uncategorizedCategory)) {
      return;
    }

    final exists = _categories.any(
      (category) =>
          _normalizeCategoryName(category.name) == normalizedSelection,
    );

    if (!exists) {
      _selectedCategory = AppConstants.systemCategoryAll;
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
      _selectedCategory = AppConstants.systemCategoryAll;

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
