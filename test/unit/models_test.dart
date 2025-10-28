import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dooit/models/task.dart';
import 'package:dooit/models/category.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Task Model Tests', () {
    test('creates task with default values', () {
      final task = Task(title: 'Test Task');

      expect(task.title, 'Test Task');
      expect(task.description, '');
      expect(task.priority, TaskPriority.medium);
      expect(task.category, 'General');
      expect(task.isCompleted, false);
      expect(task.hasNotification, false);
      expect(task.dueDate, isNull);
      expect(task.completedAt, isNull);
      expect(task.id, isNotEmpty);
      expect(task.createdAt, isNotNull);
    });

    test('creates task with custom values', () {
      final now = DateTime.now();
      final dueDate = now.add(const Duration(days: 1));

      final task = Task(
        id: 'custom-id',
        title: 'Custom Task',
        description: 'Custom description',
        priority: TaskPriority.high,
        category: 'Work',
        isCompleted: true,
        hasNotification: true,
        dueDate: dueDate,
        createdAt: now,
        completedAt: now,
      );

      expect(task.id, 'custom-id');
      expect(task.title, 'Custom Task');
      expect(task.description, 'Custom description');
      expect(task.priority, TaskPriority.high);
      expect(task.category, 'Work');
      expect(task.isCompleted, true);
      expect(task.hasNotification, true);
      expect(task.dueDate, dueDate);
      expect(task.createdAt, now);
      expect(task.completedAt, now);
    });

    test('generates unique IDs', () {
      final task1 = Task(title: 'Task 1');
      final task2 = Task(title: 'Task 2');

      expect(task1.id, isNot(task2.id));
    });

    test('copyWith creates new task with updated fields', () {
      final original = Task(
        title: 'Original',
        description: 'Description',
        priority: TaskPriority.low,
      );

      final updated = original.copyWith(
        title: 'Updated',
        priority: TaskPriority.high,
      );

      expect(updated.title, 'Updated');
      expect(updated.priority, TaskPriority.high);
      expect(updated.description, 'Description');
      expect(updated.id, original.id);
    });

    test('copyWith preserves original when no fields specified', () {
      final original = Task(title: 'Original');
      final copy = original.copyWith();

      expect(copy.title, original.title);
      expect(copy.id, original.id);
      expect(copy.priority, original.priority);
    });

    test('equality based on id', () {
      final task1 = Task(id: 'same-id', title: 'Task 1');
      final task2 = Task(id: 'same-id', title: 'Task 2');
      final task3 = Task(id: 'different-id', title: 'Task 1');

      expect(task1 == task2, true);
      expect(task1 == task3, false);
    });

    test('hashCode based on id', () {
      final task1 = Task(id: 'same-id', title: 'Task 1');
      final task2 = Task(id: 'same-id', title: 'Task 2');

      expect(task1.hashCode, task2.hashCode);
    });

    test('toString contains task information', () {
      final task = Task(
        id: 'test-id',
        title: 'Test Task',
        priority: TaskPriority.high,
        category: 'Work',
        isCompleted: true,
      );

      final string = task.toString();
      expect(string, contains('test-id'));
      expect(string, contains('Test Task'));
      expect(string, contains('true'));
      expect(string, contains('high'));
      expect(string, contains('Work'));
    });

    test('TaskPriority enum values', () {
      expect(TaskPriority.values.length, 3);
      expect(TaskPriority.values, contains(TaskPriority.low));
      expect(TaskPriority.values, contains(TaskPriority.medium));
      expect(TaskPriority.values, contains(TaskPriority.high));
    });

    test('TaskPriority index ordering', () {
      expect(TaskPriority.low.index, 0);
      expect(TaskPriority.medium.index, 1);
      expect(TaskPriority.high.index, 2);
    });
  });

  group('Category Model Tests', () {
    test('creates category with required fields', () {
      final category = Category(
        name: 'Test Category',
        colorValue: Colors.blue.value,
      );

      expect(category.name, 'Test Category');
      expect(category.colorValue, Colors.blue.value);
      expect(category.color, Colors.blue);
    });

    test('color getter returns correct Color object', () {
      final category = Category(
        name: 'Test',
        colorValue: Colors.red.value,
      );

      expect(category.color, Colors.red);
      expect(category.color.value, Colors.red.value);
    });

    test('color setter updates colorValue', () {
      final category = Category(
        name: 'Test',
        colorValue: Colors.blue.value,
      );

      category.color = Colors.green;

      expect(category.color, Colors.green);
      expect(category.colorValue, Colors.green.value);
    });

    test('copyWith creates new category with updated fields', () {
      final original = Category(
        name: 'Original',
        colorValue: Colors.blue.value,
      );

      final updated = original.copyWith(name: 'Updated');

      expect(updated.name, 'Updated');
      expect(updated.colorValue, original.colorValue);
    });

    test('copyWith updates colorValue', () {
      final original = Category(
        name: 'Test',
        colorValue: Colors.blue.value,
      );

      final updated = original.copyWith(colorValue: Colors.red.value);

      expect(updated.name, original.name);
      expect(updated.colorValue, Colors.red.value);
      expect(updated.color, Colors.red);
    });

    test('equality based on name', () {
      final category1 = Category(
        name: 'Same',
        colorValue: Colors.blue.value,
      );
      final category2 = Category(
        name: 'Same',
        colorValue: Colors.red.value,
      );
      final category3 = Category(
        name: 'Different',
        colorValue: Colors.blue.value,
      );

      expect(category1 == category2, true);
      expect(category1 == category3, false);
    });

    test('hashCode based on name', () {
      final category1 = Category(
        name: 'Same',
        colorValue: Colors.blue.value,
      );
      final category2 = Category(
        name: 'Same',
        colorValue: Colors.red.value,
      );

      expect(category1.hashCode, category2.hashCode);
    });

    test('toString contains category information', () {
      final category = Category(
        name: 'Test Category',
        colorValue: Colors.blue.value,
      );

      final string = category.toString();
      expect(string, contains('Test Category'));
      expect(string, contains('Color'));
    });

    test('getDefaultCategories returns predefined categories', () {
      final categories = Category.getDefaultCategories();

      expect(categories.length, 6);
      expect(categories.any((c) => c.name == 'General'), true);
      expect(categories.any((c) => c.name == 'Work'), true);
      expect(categories.any((c) => c.name == 'Personal'), true);
      expect(categories.any((c) => c.name == 'Shopping'), true);
      expect(categories.any((c) => c.name == 'Health'), true);
      expect(categories.any((c) => c.name == 'Education'), true);
    });

    test('default categories have valid colors', () {
      final categories = Category.getDefaultCategories();

      for (final category in categories) {
        expect(category.colorValue, isPositive);
        expect(category.color, isA<Color>());
      }
    });

    test('default categories are unique by name', () {
      final categories = Category.getDefaultCategories();
      final names = categories.map((c) => c.name).toSet();

      expect(names.length, categories.length);
    });
  });

  group('Model Integration Tests', () {
    test('task with category relationship', () {
      final category = Category(
        name: 'Work',
        colorValue: Colors.orange.value,
      );

      final task = Task(
        title: 'Work Task',
        category: category.name,
      );

      expect(task.category, category.name);
    });

    test('multiple tasks can share same category', () {
      final categoryName = 'Shared Category';
      
      final task1 = Task(title: 'Task 1', category: categoryName);
      final task2 = Task(title: 'Task 2', category: categoryName);

      expect(task1.category, task2.category);
      expect(task1.id, isNot(task2.id));
    });

    test('task lifecycle with timestamps', () {
      final createdAt = DateTime.now();
      final task = Task(
        title: 'Test',
        createdAt: createdAt,
        isCompleted: false,
      );

      expect(task.createdAt, createdAt);
      expect(task.completedAt, isNull);

      final completedAt = DateTime.now();
      final completedTask = task.copyWith(
        isCompleted: true,
        completedAt: completedAt,
      );

      expect(completedTask.isCompleted, true);
      expect(completedTask.completedAt, completedAt);
    });
  });
}
