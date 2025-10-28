import 'package:timezone/timezone.dart' as tz;

import '../models/recurrence.dart';
import '../models/task.dart';

class RecurrenceService {
  const RecurrenceService();

  DateTime? getNextOccurrence(Task task, DateTime fromDate) {
    final recurrence = _resolveRecurrence(task);
    if (recurrence == null) {
      return null;
    }

    final tz.TZDateTime reference = _toLocalTz(fromDate);
    final DateTime? next = recurrence.getNextOccurrence(reference);

    if (next == null) {
      return null;
    }

    final DateTime? endDate = task.recurrenceEndDate ?? recurrence.endDate;
    if (endDate != null && next.isAfter(endDate)) {
      return null;
    }

    return next;
  }

  bool shouldGenerateNextInstance(Task task) {
    if (!task.isCompleted) {
      return false;
    }

    final recurrence = _resolveRecurrence(task);
    if (recurrence == null) {
      return false;
    }

    final DateTime? reference = task.dueDate ?? task.completedAt;
    if (reference == null) {
      return false;
    }

    final DateTime? next = getNextOccurrence(task, reference);
    return next != null;
  }

  Task generateNextInstance(Task recurringTask) {
    final recurrence = _resolveRecurrence(recurringTask);
    if (recurrence == null) {
      throw StateError('Task ${recurringTask.id} is not configured for recurrence');
    }

    final DateTime reference = recurringTask.dueDate ?? recurringTask.completedAt ?? DateTime.now();
    final DateTime? nextDueDate = getNextOccurrence(recurringTask, reference);

    if (nextDueDate == null) {
      throw StateError('No further occurrences can be generated for task ${recurringTask.id}');
    }

    final String parentId =
        recurringTask.parentRecurringTaskId ?? recurringTask.id;

    return Task(
      title: recurringTask.title,
      description: recurringTask.description,
      dueDate: nextDueDate,
      priority: recurringTask.priority,
      category: recurringTask.category,
      hasNotification: recurringTask.hasNotification,
      recurrenceType: recurringTask.recurrenceType ?? recurrence.type,
      recurrenceInterval: recurringTask.recurrenceInterval ?? recurrence.interval,
      recurrenceEndDate: recurringTask.recurrenceEndDate ?? recurrence.endDate,
      parentRecurringTaskId: parentId,
      isRecurringInstance: true,
      recurrenceRule: _cloneRecurrence(
        recurringTask.recurrenceRule ?? recurrence,
      ),
    );
  }

  List<Task> generateInstancesForDateRange(
    Task task,
    DateTime start,
    DateTime end,
  ) {
    final recurrence = _resolveRecurrence(task);
    if (recurrence == null || task.dueDate == null) {
      return const <Task>[];
    }

    if (end.isBefore(start)) {
      return const <Task>[];
    }

    final List<Task> instances = [];
    DateTime? occurrence = task.dueDate;

    while (occurrence != null && occurrence.isBefore(start)) {
      occurrence = recurrence.getNextOccurrence(_toLocalTz(occurrence));
    }

    while (occurrence != null && !occurrence.isAfter(end)) {
      instances.add(
        Task(
          title: task.title,
          description: task.description,
          dueDate: occurrence,
          priority: task.priority,
          category: task.category,
          hasNotification: task.hasNotification,
          recurrenceType: task.recurrenceType ?? recurrence.type,
          recurrenceInterval:
              task.recurrenceInterval ?? recurrence.interval,
          recurrenceEndDate: task.recurrenceEndDate ?? recurrence.endDate,
          parentRecurringTaskId: task.parentRecurringTaskId ?? task.id,
          isRecurringInstance: true,
          recurrenceRule: _cloneRecurrence(
            task.recurrenceRule ?? recurrence,
          ),
        ),
      );

      occurrence = recurrence.getNextOccurrence(_toLocalTz(occurrence));
    }

    return instances;
  }

  Recurrence? buildRecurrenceFromTask(Task task) => _resolveRecurrence(task);

  Recurrence? _resolveRecurrence(Task task) {
    final Recurrence? rule = task.recurrenceRule;
    final RecurrenceType? type =
        task.recurrenceType ?? rule?.type ?? RecurrenceType.none;

    if (type == null || type == RecurrenceType.none) {
      return null;
    }

    final int rawInterval = task.recurrenceInterval ?? rule?.interval ?? 1;
    final int interval = rawInterval <= 0 ? 1 : rawInterval;
    final DateTime? endDate = task.recurrenceEndDate ?? rule?.endDate;

    List<int>? weekdays;
    if (rule != null && rule.weekdays != null && rule.weekdays!.isNotEmpty) {
      weekdays = List<int>.from(rule.weekdays!);
    }

    int? monthDay = rule?.monthDay;
    bool useLastDay;

    if (rule != null) {
      useLastDay = rule.useLastDayOfMonth;
    } else if (task.dueDate != null) {
      useLastDay = _isLastDayOfMonth(task.dueDate!);
    } else {
      useLastDay = false;
    }

    if (weekdays != null && weekdays.isNotEmpty) {
      final sanitized = <int>{};
      for (final day in weekdays) {
        if (day >= DateTime.monday && day <= DateTime.sunday) {
          sanitized.add(day);
        }
      }
      weekdays = sanitized.toList()..sort();
    }

    if (weekdays == null && type == RecurrenceType.weekly) {
      final weekday = task.dueDate?.weekday ?? DateTime.now().weekday;
      weekdays = [weekday];
    }

    if (type == RecurrenceType.monthly && monthDay == null && task.dueDate != null) {
      monthDay = task.dueDate!.day;
    }

    if (monthDay != null && (monthDay! < 1 || monthDay! > 31)) {
      monthDay = null;
    }

    return Recurrence(
      type: type,
      interval: interval,
      endDate: endDate,
      weekdays: weekdays,
      monthDay: monthDay,
      useLastDayOfMonth: useLastDay,
    );
  }

  Recurrence _cloneRecurrence(Recurrence recurrence) {
    return Recurrence(
      type: recurrence.type,
      interval: recurrence.interval,
      endDate: recurrence.endDate,
      weekdays: recurrence.weekdays != null
          ? List<int>.from(recurrence.weekdays!)
          : null,
      monthDay: recurrence.monthDay,
      useLastDayOfMonth: recurrence.useLastDayOfMonth,
    );
  }

  tz.TZDateTime _toLocalTz(DateTime dateTime) {
    if (dateTime is tz.TZDateTime) {
      return dateTime;
    }
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  bool _isLastDayOfMonth(DateTime date) {
    final int lastDay = DateTime(date.year, date.month + 1, 0).day;
    return date.day == lastDay;
  }
}
