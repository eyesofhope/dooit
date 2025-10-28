import 'package:dooit/models/task.dart';
import 'package:dooit/models/category.dart';
import 'package:flutter/material.dart';

class TestData {
  static Task createTask({
    String? id,
    String title = 'Test Task',
    String description = 'Test Description',
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    String category = 'General',
    bool isCompleted = false,
    DateTime? createdAt,
    DateTime? completedAt,
    bool hasNotification = false,
  }) {
    return Task(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      category: category,
      isCompleted: isCompleted,
      createdAt: createdAt,
      completedAt: completedAt,
      hasNotification: hasNotification,
    );
  }

  static Category createCategory({
    String name = 'Test Category',
    int? colorValue,
  }) {
    return Category(
      name: name,
      colorValue: colorValue ?? Colors.blue.value,
    );
  }

  static List<Task> createTaskList({int count = 5}) {
    return List.generate(
      count,
      (index) => createTask(
        title: 'Task ${index + 1}',
        description: 'Description ${index + 1}',
      ),
    );
  }

  static List<Task> createTasksWithPriorities() {
    return [
      createTask(title: 'Low Priority Task', priority: TaskPriority.low),
      createTask(title: 'Medium Priority Task', priority: TaskPriority.medium),
      createTask(title: 'High Priority Task', priority: TaskPriority.high),
    ];
  }

  static List<Task> createTasksWithDates() {
    final now = DateTime.now();
    return [
      createTask(
        title: 'Past Due Task',
        dueDate: now.subtract(const Duration(days: 2)),
      ),
      createTask(
        title: 'Today Task',
        dueDate: now,
      ),
      createTask(
        title: 'Future Task',
        dueDate: now.add(const Duration(days: 2)),
      ),
      createTask(
        title: 'No Due Date Task',
        dueDate: null,
      ),
    ];
  }

  static List<Task> createCompletedAndPendingTasks() {
    return [
      createTask(
        title: 'Completed Task 1',
        isCompleted: true,
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      createTask(
        title: 'Completed Task 2',
        isCompleted: true,
        completedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      createTask(title: 'Pending Task 1', isCompleted: false),
      createTask(title: 'Pending Task 2', isCompleted: false),
    ];
  }

  static List<Task> createTasksWithCategories() {
    return [
      createTask(title: 'Work Task 1', category: 'Work'),
      createTask(title: 'Work Task 2', category: 'Work'),
      createTask(title: 'Personal Task 1', category: 'Personal'),
      createTask(title: 'Personal Task 2', category: 'Personal'),
      createTask(title: 'General Task', category: 'General'),
    ];
  }

  static List<Category> createDefaultCategories() {
    return Category.getDefaultCategories();
  }
}
