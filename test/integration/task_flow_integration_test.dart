import 'package:flutter_test/flutter_test.dart';
import 'package:dooit/models/task.dart';
import 'package:dooit/providers/task_provider.dart';
import 'package:dooit/utils/app_utils.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Task Flow Integration Tests', () {
    late TaskProvider provider;

    setUp(() {
      provider = TaskProvider();
    });

    test('complete task workflow - create, update, complete, delete', () async {
      expect(provider.totalTasks, 0);

      final task = TestData.createTask(
        title: 'Integration Test Task',
        description: 'Testing the complete workflow',
        priority: TaskPriority.high,
        category: 'Work',
      );

      await provider.addTask(task);
      expect(provider.totalTasks, 1);
      expect(provider.pendingTasks, 1);
      expect(provider.completedTasks, 0);

      final updatedTask = task.copyWith(
        title: 'Updated Task Title',
        priority: TaskPriority.low,
      );
      await provider.updateTask(updatedTask);
      
      final retrievedTask = provider.getTaskById(task.id);
      expect(retrievedTask?.title, 'Updated Task Title');
      expect(retrievedTask?.priority, TaskPriority.low);

      await provider.toggleTaskCompletion(task.id);
      expect(provider.completedTasks, 1);
      expect(provider.pendingTasks, 0);
      expect(provider.completionPercentage, 100.0);

      await provider.toggleTaskCompletion(task.id);
      expect(provider.completedTasks, 0);
      expect(provider.pendingTasks, 1);

      await provider.deleteTask(task.id);
      expect(provider.totalTasks, 0);
    });

    test('category management workflow', () async {
      final category = TestData.createCategory(name: 'Test Category');
      await provider.addCategory(category);

      expect(provider.categories.length, 1);

      await provider.addTask(TestData.createTask(category: 'Test Category'));
      await provider.addTask(TestData.createTask(category: 'Test Category'));
      await provider.addTask(TestData.createTask(category: 'General'));

      expect(provider.getTasksByCategory('Test Category').length, 2);

      await provider.deleteCategory('Test Category');
      expect(provider.categories.length, 0);
      
      expect(provider.allTasks.where((t) => t.category == 'General').length, 3);
    });

    test('search, filter, and sort workflow', () async {
      final now = DateTime.now();
      
      await provider.addTask(TestData.createTask(
        title: 'Buy groceries',
        category: 'Shopping',
        priority: TaskPriority.high,
        isCompleted: false,
      ));
      
      await provider.addTask(TestData.createTask(
        title: 'Write report',
        category: 'Work',
        priority: TaskPriority.medium,
        isCompleted: true,
      ));
      
      await provider.addTask(TestData.createTask(
        title: 'Buy books',
        category: 'Shopping',
        priority: TaskPriority.low,
        isCompleted: false,
        dueDate: now.subtract(const Duration(days: 1)),
      ));

      expect(provider.allTasks.length, 3);

      provider.setSearchQuery('buy');
      expect(provider.tasks.length, 2);

      provider.setSearchQuery('');
      provider.setSelectedCategory('Shopping');
      expect(provider.tasks.length, 2);

      provider.setSelectedCategory('All');
      provider.setFilterOption(FilterOption.completed);
      expect(provider.tasks.length, 1);

      provider.setFilterOption(FilterOption.overdue);
      expect(provider.tasks.length, 1);
      expect(provider.tasks.first.title, 'Buy books');

      provider.setFilterOption(FilterOption.all);
      provider.setSortOption(SortOption.priority);
      expect(provider.tasks.first.priority, TaskPriority.high);
      expect(provider.tasks.last.priority, TaskPriority.low);

      provider.setSortOption(SortOption.alphabetical);
      expect(provider.tasks.first.title, 'Buy books');
      expect(provider.tasks.last.title, 'Write report');
    });

    test('statistics workflow', () async {
      expect(provider.completionPercentage, 0.0);

      await provider.addTask(TestData.createTask(isCompleted: true));
      expect(provider.completionPercentage, 100.0);

      await provider.addTask(TestData.createTask(isCompleted: false));
      expect(provider.completionPercentage, 50.0);

      await provider.addTask(TestData.createTask(isCompleted: false));
      expect(provider.completionPercentage, closeTo(33.33, 0.1));

      await provider.addTask(TestData.createTask(isCompleted: true));
      expect(provider.completionPercentage, 50.0);
    });

    test('multiple category task distribution', () async {
      await provider.addTask(TestData.createTask(category: 'Work'));
      await provider.addTask(TestData.createTask(category: 'Work'));
      await provider.addTask(TestData.createTask(category: 'Work'));
      await provider.addTask(TestData.createTask(category: 'Personal'));
      await provider.addTask(TestData.createTask(category: 'Personal'));
      await provider.addTask(TestData.createTask(category: 'Shopping'));

      final stats = provider.getCategoryStats();
      expect(stats['Work'], 3);
      expect(stats['Personal'], 2);
      expect(stats['Shopping'], 1);
    });

    test('priority distribution for pending tasks', () async {
      await provider.addTask(TestData.createTask(
        priority: TaskPriority.high,
        isCompleted: false,
      ));
      await provider.addTask(TestData.createTask(
        priority: TaskPriority.high,
        isCompleted: false,
      ));
      await provider.addTask(TestData.createTask(
        priority: TaskPriority.medium,
        isCompleted: false,
      ));
      await provider.addTask(TestData.createTask(
        priority: TaskPriority.low,
        isCompleted: true,
      ));

      final stats = provider.getPriorityStats();
      expect(stats[TaskPriority.high], 2);
      expect(stats[TaskPriority.medium], 1);
      expect(stats[TaskPriority.low], isNull);
    });

    test('filter and sort combinations', () async {
      final now = DateTime.now();
      
      await provider.addTask(TestData.createTask(
        title: 'A Task',
        priority: TaskPriority.high,
        isCompleted: false,
        dueDate: now.add(const Duration(days: 1)),
      ));
      
      await provider.addTask(TestData.createTask(
        title: 'B Task',
        priority: TaskPriority.medium,
        isCompleted: false,
        dueDate: now.subtract(const Duration(days: 1)),
      ));
      
      await provider.addTask(TestData.createTask(
        title: 'C Task',
        priority: TaskPriority.low,
        isCompleted: true,
      ));

      provider.setFilterOption(FilterOption.pending);
      provider.setSortOption(SortOption.alphabetical);
      
      expect(provider.tasks.length, 2);
      expect(provider.tasks.first.title, 'A Task');

      provider.setFilterOption(FilterOption.overdue);
      expect(provider.tasks.length, 1);
      expect(provider.tasks.first.title, 'B Task');
    });

    test('bulk operations', () async {
      final tasks = TestData.createTaskList(count: 10);
      
      for (final task in tasks) {
        await provider.addTask(task);
      }
      
      expect(provider.totalTasks, 10);

      for (int i = 0; i < 5; i++) {
        await provider.toggleTaskCompletion(provider.allTasks[i].id);
      }
      
      expect(provider.completedTasks, 5);
      expect(provider.completionPercentage, 50.0);

      await provider.clearAllData();
      
      expect(provider.totalTasks, 0);
      expect(provider.completionPercentage, 0.0);
    });

    test('edge case - empty state transitions', () async {
      expect(provider.totalTasks, 0);
      expect(provider.completionPercentage, 0.0);

      await provider.addTask(TestData.createTask());
      expect(provider.totalTasks, 1);

      await provider.clearAllData();
      expect(provider.totalTasks, 0);
      expect(provider.completionPercentage, 0.0);
    });

    test('concurrent operations', () async {
      final task1 = TestData.createTask(title: 'Task 1');
      final task2 = TestData.createTask(title: 'Task 2');
      final task3 = TestData.createTask(title: 'Task 3');

      await Future.wait([
        provider.addTask(task1),
        provider.addTask(task2),
        provider.addTask(task3),
      ]);

      expect(provider.totalTasks, 3);

      await Future.wait([
        provider.toggleTaskCompletion(task1.id),
        provider.toggleTaskCompletion(task2.id),
      ]);

      expect(provider.completedTasks, 2);
    });
  });

  group('AppUtils Integration with TaskProvider', () {
    late TaskProvider provider;

    setUp(() {
      provider = TaskProvider();
    });

    test('sorting integration', () async {
      final now = DateTime.now();
      
      await provider.addTask(TestData.createTask(
        title: 'Z Task',
        createdAt: now.subtract(const Duration(days: 3)),
      ));
      
      await provider.addTask(TestData.createTask(
        title: 'A Task',
        createdAt: now.subtract(const Duration(days: 2)),
      ));
      
      await provider.addTask(TestData.createTask(
        title: 'M Task',
        createdAt: now.subtract(const Duration(days: 1)),
      ));

      provider.setSortOption(SortOption.alphabetical);
      expect(provider.tasks.first.title, 'A Task');

      provider.setSortOption(SortOption.createdDate);
      expect(provider.tasks.first.title, 'M Task');
    });

    test('filtering integration', () async {
      final now = DateTime.now();
      
      await provider.addTask(TestData.createTask(isCompleted: true));
      await provider.addTask(TestData.createTask(isCompleted: false));
      await provider.addTask(TestData.createTask(
        isCompleted: false,
        dueDate: now.subtract(const Duration(days: 1)),
      ));

      provider.setFilterOption(FilterOption.all);
      expect(provider.tasks.length, 3);

      provider.setFilterOption(FilterOption.completed);
      expect(provider.tasks.length, 1);

      provider.setFilterOption(FilterOption.pending);
      expect(provider.tasks.length, 2);

      provider.setFilterOption(FilterOption.overdue);
      expect(provider.tasks.length, 1);
    });
  });
}
