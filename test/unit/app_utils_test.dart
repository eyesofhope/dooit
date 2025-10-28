import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dooit/utils/app_utils.dart';
import 'package:dooit/models/task.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('AppUtils - Priority Functions', () {
    test('getPriorityLabel returns correct labels', () {
      expect(AppUtils.getPriorityLabel(TaskPriority.low), 'Low');
      expect(AppUtils.getPriorityLabel(TaskPriority.medium), 'Medium');
      expect(AppUtils.getPriorityLabel(TaskPriority.high), 'High');
    });

    test('getPriorityColor returns correct colors', () {
      expect(AppUtils.getPriorityColor(TaskPriority.low), Colors.green);
      expect(AppUtils.getPriorityColor(TaskPriority.medium), Colors.orange);
      expect(AppUtils.getPriorityColor(TaskPriority.high), Colors.red);
    });
  });

  group('AppUtils - Date Formatting', () {
    test('formatDate formats date correctly', () {
      final date = DateTime(2024, 1, 5);
      expect(AppUtils.formatDate(date), '05/01/2024');
    });

    test('formatDate handles single digit days and months', () {
      final date = DateTime(2024, 3, 7);
      expect(AppUtils.formatDate(date), '07/03/2024');
    });

    test('formatDate returns empty string for null date', () {
      expect(AppUtils.formatDate(null), '');
    });

    test('formatDateTime formats date and time correctly', () {
      final dateTime = DateTime(2024, 1, 5, 14, 30);
      expect(AppUtils.formatDateTime(dateTime), '05/01/2024 14:30');
    });

    test('formatDateTime handles single digit hours and minutes', () {
      final dateTime = DateTime(2024, 3, 7, 9, 5);
      expect(AppUtils.formatDateTime(dateTime), '07/03/2024 09:05');
    });

    test('formatDateTime returns empty string for null', () {
      expect(AppUtils.formatDateTime(null), '');
    });
  });

  group('AppUtils - isOverdue', () {
    test('returns true for past dates', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      expect(AppUtils.isOverdue(pastDate), isTrue);
    });

    test('returns false for future dates', () {
      final futureDate = DateTime.now().add(const Duration(days: 1));
      expect(AppUtils.isOverdue(futureDate), isFalse);
    });

    test('returns false for null date', () {
      expect(AppUtils.isOverdue(null), isFalse);
    });

    test('returns true for dates in the past by seconds', () {
      final pastDate = DateTime.now().subtract(const Duration(seconds: 10));
      expect(AppUtils.isOverdue(pastDate), isTrue);
    });
  });

  group('AppUtils - getTimeAgo', () {
    test('returns "Just now" for very recent times', () {
      final now = DateTime.now();
      expect(AppUtils.getTimeAgo(now), 'Just now');
    });

    test('returns correct minutes ago', () {
      final time = DateTime.now().subtract(const Duration(minutes: 5));
      expect(AppUtils.getTimeAgo(time), '5 minutes ago');
    });

    test('returns singular minute', () {
      final time = DateTime.now().subtract(const Duration(minutes: 1));
      expect(AppUtils.getTimeAgo(time), '1 minute ago');
    });

    test('returns correct hours ago', () {
      final time = DateTime.now().subtract(const Duration(hours: 3));
      expect(AppUtils.getTimeAgo(time), '3 hours ago');
    });

    test('returns singular hour', () {
      final time = DateTime.now().subtract(const Duration(hours: 1));
      expect(AppUtils.getTimeAgo(time), '1 hour ago');
    });

    test('returns correct days ago', () {
      final time = DateTime.now().subtract(const Duration(days: 2));
      expect(AppUtils.getTimeAgo(time), '2 days ago');
    });

    test('returns singular day', () {
      final time = DateTime.now().subtract(const Duration(days: 1));
      expect(AppUtils.getTimeAgo(time), '1 day ago');
    });
  });

  group('AppUtils - getTimeUntil', () {
    test('returns "overdue" for past dates', () {
      final pastDate = DateTime.now().subtract(const Duration(hours: 1));
      expect(AppUtils.getTimeUntil(pastDate), 'overdue');
    });

    test('returns correct seconds', () {
      final future = DateTime.now().add(const Duration(seconds: 30));
      expect(AppUtils.getTimeUntil(future), '30 seconds');
    });

    test('returns singular second', () {
      final future = DateTime.now().add(const Duration(seconds: 1));
      expect(AppUtils.getTimeUntil(future), '1 second');
    });

    test('returns correct minutes', () {
      final future = DateTime.now().add(const Duration(minutes: 15));
      expect(AppUtils.getTimeUntil(future), 'in 15 minutes');
    });

    test('returns singular minute', () {
      final future = DateTime.now().add(const Duration(minutes: 1));
      expect(AppUtils.getTimeUntil(future), 'in 1 minute');
    });

    test('returns correct hours', () {
      final future = DateTime.now().add(const Duration(hours: 4));
      expect(AppUtils.getTimeUntil(future), 'in 4 hours');
    });

    test('returns singular hour', () {
      final future = DateTime.now().add(const Duration(hours: 1));
      expect(AppUtils.getTimeUntil(future), 'in 1 hour');
    });

    test('returns correct days', () {
      final future = DateTime.now().add(const Duration(days: 3));
      expect(AppUtils.getTimeUntil(future), 'in 3 days');
    });

    test('returns singular day', () {
      final future = DateTime.now().add(const Duration(days: 1));
      expect(AppUtils.getTimeUntil(future), 'in 1 day');
    });
  });

  group('AppUtils - sortTasks', () {
    test('sorts by due date with null dates at end', () {
      final tasks = TestData.createTasksWithDates();
      final sorted = AppUtils.sortTasks(tasks, SortOption.dueDate);

      expect(sorted[0].title, 'Past Due Task');
      expect(sorted[1].title, 'Today Task');
      expect(sorted[2].title, 'Future Task');
      expect(sorted[3].title, 'No Due Date Task');
    });

    test('sorts by priority (high to low)', () {
      final tasks = TestData.createTasksWithPriorities();
      final sorted = AppUtils.sortTasks(tasks, SortOption.priority);

      expect(sorted[0].priority, TaskPriority.high);
      expect(sorted[1].priority, TaskPriority.medium);
      expect(sorted[2].priority, TaskPriority.low);
    });

    test('sorts by created date (newest first)', () {
      final now = DateTime.now();
      final tasks = [
        TestData.createTask(
          title: 'Oldest',
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        TestData.createTask(
          title: 'Middle',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        TestData.createTask(
          title: 'Newest',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final sorted = AppUtils.sortTasks(tasks, SortOption.createdDate);

      expect(sorted[0].title, 'Newest');
      expect(sorted[1].title, 'Middle');
      expect(sorted[2].title, 'Oldest');
    });

    test('sorts alphabetically', () {
      final tasks = [
        TestData.createTask(title: 'Zebra'),
        TestData.createTask(title: 'Apple'),
        TestData.createTask(title: 'Banana'),
      ];

      final sorted = AppUtils.sortTasks(tasks, SortOption.alphabetical);

      expect(sorted[0].title, 'Apple');
      expect(sorted[1].title, 'Banana');
      expect(sorted[2].title, 'Zebra');
    });

    test('sorts alphabetically case-insensitive', () {
      final tasks = [
        TestData.createTask(title: 'zebra'),
        TestData.createTask(title: 'APPLE'),
        TestData.createTask(title: 'Banana'),
      ];

      final sorted = AppUtils.sortTasks(tasks, SortOption.alphabetical);

      expect(sorted[0].title, 'APPLE');
      expect(sorted[1].title, 'Banana');
      expect(sorted[2].title, 'zebra');
    });

    test('sorts by completion status (pending first)', () {
      final tasks = TestData.createCompletedAndPendingTasks();
      final sorted = AppUtils.sortTasks(tasks, SortOption.completionStatus);

      expect(sorted[0].isCompleted, false);
      expect(sorted[1].isCompleted, false);
      expect(sorted[2].isCompleted, true);
      expect(sorted[3].isCompleted, true);
    });

    test('returns new list without modifying original', () {
      final tasks = TestData.createTasksWithPriorities();
      final originalOrder = tasks.map((t) => t.title).toList();

      AppUtils.sortTasks(tasks, SortOption.priority);

      final afterSort = tasks.map((t) => t.title).toList();
      expect(afterSort, originalOrder);
    });
  });

  group('AppUtils - filterTasks', () {
    late List<Task> tasks;

    setUp(() {
      final now = DateTime.now();
      tasks = [
        TestData.createTask(
          title: 'Completed',
          isCompleted: true,
          completedAt: now,
        ),
        TestData.createTask(
          title: 'Pending',
          isCompleted: false,
        ),
        TestData.createTask(
          title: 'Overdue',
          isCompleted: false,
          dueDate: now.subtract(const Duration(days: 1)),
        ),
        TestData.createTask(
          title: 'Pending Future',
          isCompleted: false,
          dueDate: now.add(const Duration(days: 1)),
        ),
      ];
    });

    test('FilterOption.all returns all tasks', () {
      final filtered = AppUtils.filterTasks(tasks, FilterOption.all);
      expect(filtered.length, 4);
    });

    test('FilterOption.completed returns only completed tasks', () {
      final filtered = AppUtils.filterTasks(tasks, FilterOption.completed);
      expect(filtered.length, 1);
      expect(filtered[0].title, 'Completed');
    });

    test('FilterOption.pending returns only pending tasks', () {
      final filtered = AppUtils.filterTasks(tasks, FilterOption.pending);
      expect(filtered.length, 3);
      expect(filtered.every((task) => !task.isCompleted), isTrue);
    });

    test('FilterOption.overdue returns only overdue incomplete tasks', () {
      final filtered = AppUtils.filterTasks(tasks, FilterOption.overdue);
      expect(filtered.length, 1);
      expect(filtered[0].title, 'Overdue');
      expect(filtered[0].isCompleted, isFalse);
    });

    test('filters empty list correctly', () {
      final emptyList = <Task>[];
      expect(AppUtils.filterTasks(emptyList, FilterOption.all).length, 0);
      expect(AppUtils.filterTasks(emptyList, FilterOption.completed).length, 0);
      expect(AppUtils.filterTasks(emptyList, FilterOption.pending).length, 0);
      expect(AppUtils.filterTasks(emptyList, FilterOption.overdue).length, 0);
    });
  });

  group('AppUtils - Edge Cases', () {
    test('handles tasks with null due dates in sorting', () {
      final tasks = [
        TestData.createTask(title: 'Task 1', dueDate: null),
        TestData.createTask(title: 'Task 2', dueDate: null),
      ];

      final sorted = AppUtils.sortTasks(tasks, SortOption.dueDate);
      expect(sorted.length, 2);
    });

    test('handles empty task list in sorting', () {
      final tasks = <Task>[];
      final sorted = AppUtils.sortTasks(tasks, SortOption.dueDate);
      expect(sorted.length, 0);
    });

    test('handles single task in sorting', () {
      final tasks = [TestData.createTask()];
      final sorted = AppUtils.sortTasks(tasks, SortOption.priority);
      expect(sorted.length, 1);
    });

    test('formatDate handles leap year dates', () {
      final leapYearDate = DateTime(2024, 2, 29);
      expect(AppUtils.formatDate(leapYearDate), '29/02/2024');
    });

    test('formatDate handles year boundaries', () {
      final newYearDate = DateTime(2024, 1, 1);
      expect(AppUtils.formatDate(newYearDate), '01/01/2024');

      final yearEndDate = DateTime(2024, 12, 31);
      expect(AppUtils.formatDate(yearEndDate), '31/12/2024');
    });
  });
}
