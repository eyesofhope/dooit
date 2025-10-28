import 'package:flutter/material.dart';
import '../models/task.dart';

class AppConstants {
  // App info
  static const String appName = 'DoIt';
  static const String appVersion = '1.0.0';

  // Schema version for migrations
  static const int currentSchemaVersion = 1;

  // Hive box names
  static const String tasksBoxName = 'tasks';
  static const String categoriesBoxName = 'categories';
  static const String settingsBoxName = 'settings';
  static const String versionBoxName = 'version';

  // Notification channel
  static const String notificationChannelId = 'task_reminders';
  static const String notificationChannelName = 'Task Reminders';
  static const String notificationChannelDescription =
      'Notifications for task due dates';

  // Default values
  static const String defaultCategory = 'General';
  static const TaskPriority defaultPriority = TaskPriority.medium;

  // Date formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // UI constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;

  // Priority colors
  static const Map<TaskPriority, Color> priorityColors = {
    TaskPriority.low: Colors.green,
    TaskPriority.medium: Colors.orange,
    TaskPriority.high: Colors.red,
  };

  // Priority labels
  static const Map<TaskPriority, String> priorityLabels = {
    TaskPriority.low: 'Low',
    TaskPriority.medium: 'Medium',
    TaskPriority.high: 'High',
  };
}

enum SortOption {
  dueDate,
  priority,
  createdDate,
  alphabetical,
  completionStatus,
  subtaskProgress,
}

enum FilterOption { all, completed, pending, overdue, incompleteSubtasks }

class AppUtils {
  static String getPriorityLabel(TaskPriority priority) {
    return AppConstants.priorityLabels[priority] ?? 'Medium';
  }

  static Color getPriorityColor(TaskPriority priority) {
    return AppConstants.priorityColors[priority] ?? Colors.orange;
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static bool isOverdue(DateTime? dueDate) {
    if (dueDate == null) return false;
    return dueDate.isBefore(DateTime.now());
  }

  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  static String getTimeUntil(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return 'in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else if (difference.inSeconds > 0) {
      return 'in ${difference.inSeconds} second${difference.inSeconds == 1 ? '' : 's'}';
    } else {
      return 'overdue';
    }
  }

  static List<Task> sortTasks(List<Task> tasks, SortOption sortOption) {
    final sortedTasks = List<Task>.from(tasks);

    switch (sortOption) {
      case SortOption.dueDate:
        sortedTasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case SortOption.priority:
        sortedTasks.sort(
          (a, b) => b.priority.index.compareTo(a.priority.index),
        );
        break;
      case SortOption.createdDate:
        sortedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.alphabetical:
        sortedTasks.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case SortOption.completionStatus:
        sortedTasks.sort(
          (a, b) => a.isCompleted == b.isCompleted
              ? 0
              : a.isCompleted
                  ? 1
                  : -1,
        );
        break;
      case SortOption.subtaskProgress:
        sortedTasks.sort((a, b) {
          if (!a.hasSubtasks && !b.hasSubtasks) return 0;
          if (!a.hasSubtasks) return 1;
          if (!b.hasSubtasks) return -1;
          return b.subtaskCompletionPercentage
              .compareTo(a.subtaskCompletionPercentage);
        });
        break;
    }

    return sortedTasks;
  }

  static List<Task> filterTasks(List<Task> tasks, FilterOption filterOption) {
    switch (filterOption) {
      case FilterOption.all:
        return tasks;
      case FilterOption.completed:
        return tasks.where((task) => task.isCompleted).toList();
      case FilterOption.pending:
        return tasks.where((task) => !task.isCompleted).toList();
      case FilterOption.overdue:
        return tasks
            .where((task) => !task.isCompleted && isOverdue(task.dueDate))
            .toList();
      case FilterOption.incompleteSubtasks:
        return tasks
            .where(
              (task) =>
                  task.hasSubtasks &&
                  task.completedSubtasksCount < task.totalSubtasksCount,
            )
            .toList();
    }
  }
}
