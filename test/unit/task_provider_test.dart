import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dooit/providers/task_provider.dart';
import 'package:dooit/models/task.dart';
import 'package:dooit/models/category.dart';
import 'package:dooit/utils/app_utils.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_helpers.dart';

class MockTaskBox extends MockBox<Task> {}

class MockCategoryBox extends MockBox<Category> {}

void main() {
  setUpAll(() {
    registerFallbackValue(TestData.createTask());
    registerFallbackValue(TestData.createCategory());
  });

  group('TaskProvider - Initialization', () {
    test('initializes with empty tasks and categories', () {
      final provider = TaskProvider();

      expect(provider.tasks, isEmpty);
      expect(provider.allTasks, isEmpty);
      expect(provider.totalTasks, 0);
      expect(provider.completedTasks, 0);
      expect(provider.pendingTasks, 0);
      expect(provider.overdueTasks, 0);
    });

    test('completion percentage is 0 when no tasks', () {
      final provider = TaskProvider();
      expect(provider.completionPercentage, 0.0);
    });
  });

  group('TaskProvider - Statistics', () {
    test('calculates statistics correctly', () async {
      final provider = TaskProvider();
      final now = DateTime.now();

      await provider.addTask(TestData.createTask(
        title: 'Completed',
        isCompleted: true,
      ));
      await provider.addTask(TestData.createTask(
        title: 'Pending',
        isCompleted: false,
      ));
      await provider.addTask(TestData.createTask(
        title: 'Overdue',
        isCompleted: false,
        dueDate: now.subtract(const Duration(days: 1)),
      ));

      expect(provider.totalTasks, 3);
      expect(provider.completedTasks, 1);
      expect(provider.pendingTasks, 2);
      expect(provider.overdueTasks, 1);
    });

    test('calculates completion percentage correctly', () async {
      final provider = TaskProvider();

      await provider.addTask(TestData.createTask(isCompleted: true));
      await provider.addTask(TestData.createTask(isCompleted: true));
      await provider.addTask(TestData.createTask(isCompleted: false));
      await provider.addTask(TestData.createTask(isCompleted: false));

      expect(provider.completionPercentage, 50.0);
    });

    test('completion percentage is 100 when all completed', () async {
      final provider = TaskProvider();

      await provider.addTask(TestData.createTask(isCompleted: true));
      await provider.addTask(TestData.createTask(isCompleted: true));

      expect(provider.completionPercentage, 100.0);
    });
  });

  group('TaskProvider - CRUD Operations', () {
    test('adds task successfully', () async {
      final provider = TaskProvider();
      final task = TestData.createTask(title: 'New Task');

      var notified = false;
      provider.addListener(() {
        notified = true;
      });

      await provider.addTask(task);

      expect(provider.allTasks.length, 1);
      expect(provider.allTasks.first.title, 'New Task');
      expect(notified, isTrue);
    });

    test('updates task successfully', () async {
      final provider = TaskProvider();
      final task = TestData.createTask(title: 'Original');

      await provider.addTask(task);

      final updatedTask = task.copyWith(title: 'Updated');
      await provider.updateTask(updatedTask);

      expect(provider.allTasks.first.title, 'Updated');
    });

    test('deletes task successfully', () async {
      final provider = TaskProvider();
      final task = TestData.createTask();

      await provider.addTask(task);
      expect(provider.allTasks.length, 1);

      await provider.deleteTask(task.id);

      expect(provider.allTasks.length, 0);
    });

    test('toggles task completion', () async {
      final provider = TaskProvider();
      final task = TestData.createTask(isCompleted: false);

      await provider.addTask(task);
      expect(provider.allTasks.first.isCompleted, false);

      await provider.toggleTaskCompletion(task.id);

      expect(provider.allTasks.first.isCompleted, true);
      expect(provider.allTasks.first.completedAt, isNotNull);
    });

    test('toggles task from completed to pending', () async {
      final provider = TaskProvider();
      final task = TestData.createTask(
        isCompleted: true,
        completedAt: DateTime.now(),
      );

      await provider.addTask(task);
      await provider.toggleTaskCompletion(task.id);

      expect(provider.allTasks.first.isCompleted, false);
      expect(provider.allTasks.first.completedAt, isNull);
    });
  });

  group('TaskProvider - Category Operations', () {
    test('adds category successfully', () async {
      final provider = TaskProvider();
      final category = TestData.createCategory(name: 'New Category');

      var notified = false;
      provider.addListener(() {
        notified = true;
      });

      await provider.addCategory(category);

      expect(provider.categories.length, 1);
      expect(provider.categories.first.name, 'New Category');
      expect(notified, isTrue);
    });

    test('updates category successfully', () async {
      final provider = TaskProvider();
      final category = TestData.createCategory(name: 'Test');

      await provider.addCategory(category);

      final updatedCategory = category.copyWith(name: 'Test');
      await provider.updateCategory(updatedCategory);

      expect(provider.categories.first.name, 'Test');
    });

    test('deletes category and updates tasks', () async {
      final provider = TaskProvider();
      final category = TestData.createCategory(name: 'ToDelete');

      await provider.addCategory(category);
      await provider.addTask(TestData.createTask(category: 'ToDelete'));

      await provider.deleteCategory('ToDelete');

      expect(provider.categories, isEmpty);
      expect(provider.allTasks.first.category, 'General');
    });

    test('resets selected category when deleted', () async {
      final provider = TaskProvider();
      final category = TestData.createCategory(name: 'TestCategory');

      await provider.addCategory(category);
      provider.setSelectedCategory('TestCategory');

      await provider.deleteCategory('TestCategory');

      expect(provider.selectedCategory, 'All');
    });
  });

  group('TaskProvider - Search and Filter', () {
    late TaskProvider provider;

    setUp(() async {
      provider = TaskProvider();
      await provider.addTask(TestData.createTask(
        title: 'Buy groceries',
        description: 'Milk and bread',
        category: 'Shopping',
      ));
      await provider.addTask(TestData.createTask(
        title: 'Write report',
        description: 'Quarterly report',
        category: 'Work',
      ));
      await provider.addTask(TestData.createTask(
        title: 'Buy books',
        description: 'Programming books',
        category: 'Shopping',
      ));
    });

    test('searches by title', () {
      provider.setSearchQuery('buy');
      expect(provider.tasks.length, 2);
    });

    test('searches by description', () {
      provider.setSearchQuery('report');
      expect(provider.tasks.length, 1);
      expect(provider.tasks.first.title, 'Write report');
    });

    test('searches by category', () {
      provider.setSearchQuery('shopping');
      expect(provider.tasks.length, 2);
    });

    test('search is case insensitive', () {
      provider.setSearchQuery('BUY');
      expect(provider.tasks.length, 2);
    });

    test('filters by category', () {
      provider.setSelectedCategory('Shopping');
      expect(provider.tasks.length, 2);
    });

    test('filters by completion status', () async {
      await provider.addTask(TestData.createTask(
        title: 'Completed task',
        isCompleted: true,
      ));

      provider.setFilterOption(FilterOption.completed);
      expect(provider.tasks.length, 1);

      provider.setFilterOption(FilterOption.pending);
      expect(provider.tasks.length, 3);
    });

    test('filters by overdue status', () async {
      await provider.addTask(TestData.createTask(
        title: 'Overdue task',
        isCompleted: false,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      ));

      provider.setFilterOption(FilterOption.overdue);
      expect(provider.tasks.length, 1);
    });

    test('sorts tasks', () async {
      provider.setSortOption(SortOption.alphabetical);
      expect(provider.tasks.first.title, 'Buy books');
      expect(provider.tasks.last.title, 'Write report');
    });

    test('combines search and filter', () {
      provider.setSearchQuery('buy');
      provider.setSelectedCategory('Shopping');
      expect(provider.tasks.length, 2);
    });
  });

  group('TaskProvider - Utility Methods', () {
    late TaskProvider provider;

    setUp(() async {
      provider = TaskProvider();
      await provider.addTask(TestData.createTask(
        id: 'task1',
        title: 'Task 1',
        category: 'Work',
      ));
      await provider.addTask(TestData.createTask(
        id: 'task2',
        title: 'Task 2',
        category: 'Work',
      ));
      await provider.addTask(TestData.createTask(
        id: 'task3',
        title: 'Task 3',
        category: 'Personal',
      ));
    });

    test('getTaskById returns correct task', () {
      final task = provider.getTaskById('task1');
      expect(task, isNotNull);
      expect(task!.title, 'Task 1');
    });

    test('getTaskById returns null for non-existent id', () {
      final task = provider.getTaskById('nonexistent');
      expect(task, isNull);
    });

    test('getTasksByCategory returns correct tasks', () {
      final workTasks = provider.getTasksByCategory('Work');
      expect(workTasks.length, 2);
      expect(workTasks.every((t) => t.category == 'Work'), isTrue);
    });

    test('getCategoryStats returns correct counts', () {
      final stats = provider.getCategoryStats();
      expect(stats['Work'], 2);
      expect(stats['Personal'], 1);
    });

    test('getPriorityStats returns correct counts for pending tasks', () async {
      await provider.addTask(TestData.createTask(
        priority: TaskPriority.high,
        isCompleted: false,
      ));
      await provider.addTask(TestData.createTask(
        priority: TaskPriority.high,
        isCompleted: false,
      ));
      await provider.addTask(TestData.createTask(
        priority: TaskPriority.low,
        isCompleted: true,
      ));

      final stats = provider.getPriorityStats();
      expect(stats[TaskPriority.high], 2);
      expect(stats[TaskPriority.low], isNull);
    });
  });

  group('TaskProvider - Clear Data', () {
    test('clearAllData removes all tasks and categories', () async {
      final provider = TaskProvider();

      await provider.addTask(TestData.createTask());
      await provider.addTask(TestData.createTask());
      await provider.addCategory(TestData.createCategory());

      await provider.clearAllData();

      expect(provider.allTasks, isEmpty);
      expect(provider.categories, isEmpty);
    });
  });

  group('TaskProvider - Listener Notifications', () {
    test('notifies listeners on add task', () async {
      final provider = TaskProvider();
      var notificationCount = 0;

      provider.addListener(() {
        notificationCount++;
      });

      await provider.addTask(TestData.createTask());

      expect(notificationCount, greaterThan(0));
    });

    test('notifies listeners on update task', () async {
      final provider = TaskProvider();
      final task = TestData.createTask();
      await provider.addTask(task);

      var notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });

      await provider.updateTask(task.copyWith(title: 'Updated'));

      expect(notificationCount, greaterThan(0));
    });

    test('notifies listeners on delete task', () async {
      final provider = TaskProvider();
      final task = TestData.createTask();
      await provider.addTask(task);

      var notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });

      await provider.deleteTask(task.id);

      expect(notificationCount, greaterThan(0));
    });

    test('notifies listeners on search query change', () {
      final provider = TaskProvider();
      var notified = false;

      provider.addListener(() {
        notified = true;
      });

      provider.setSearchQuery('test');

      expect(notified, isTrue);
    });

    test('notifies listeners on sort option change', () {
      final provider = TaskProvider();
      var notified = false;

      provider.addListener(() {
        notified = true;
      });

      provider.setSortOption(SortOption.priority);

      expect(notified, isTrue);
    });

    test('notifies listeners on filter option change', () {
      final provider = TaskProvider();
      var notified = false;

      provider.addListener(() {
        notified = true;
      });

      provider.setFilterOption(FilterOption.completed);

      expect(notified, isTrue);
    });
  });

  group('TaskProvider - Edge Cases', () {
    test('handles updating non-existent task gracefully', () async {
      final provider = TaskProvider();
      final task = TestData.createTask(id: 'nonexistent');

      await provider.updateTask(task);

      expect(provider.allTasks, isEmpty);
    });

    test('handles deleting non-existent task gracefully', () async {
      final provider = TaskProvider();

      await provider.deleteTask('nonexistent');

      expect(provider.allTasks, isEmpty);
    });

    test('handles toggling non-existent task gracefully', () async {
      final provider = TaskProvider();

      await provider.toggleTaskCompletion('nonexistent');

      expect(provider.allTasks, isEmpty);
    });

    test('handles multiple tasks with same title', () async {
      final provider = TaskProvider();

      await provider.addTask(TestData.createTask(title: 'Duplicate'));
      await provider.addTask(TestData.createTask(title: 'Duplicate'));

      expect(provider.allTasks.length, 2);
      expect(provider.allTasks[0].id, isNot(provider.allTasks[1].id));
    });
  });
}
