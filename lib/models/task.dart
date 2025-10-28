import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'recurrence.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
enum TaskPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  TaskPriority priority;

  @HiveField(5)
  String category;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime? completedAt;

  @HiveField(9)
  bool hasNotification;

  @HiveField(10)
  RecurrenceType? recurrenceType;

  @HiveField(11)
  int? recurrenceInterval;

  @HiveField(12)
  DateTime? recurrenceEndDate;

  @HiveField(13)
  String? parentRecurringTaskId;

  @HiveField(14)
  bool isRecurringInstance;

  @HiveField(15)
  Recurrence? recurrenceRule;

  Task({
    String? id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.category = 'General',
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
    this.hasNotification = false,
    this.recurrenceType,
    this.recurrenceInterval,
    this.recurrenceEndDate,
    this.parentRecurringTaskId,
    this.isRecurringInstance = false,
    this.recurrenceRule,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    String? category,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? hasNotification,
    RecurrenceType? recurrenceType,
    int? recurrenceInterval,
    DateTime? recurrenceEndDate,
    String? parentRecurringTaskId,
    bool? isRecurringInstance,
    Recurrence? recurrenceRule,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      hasNotification: hasNotification ?? this.hasNotification,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      parentRecurringTaskId:
          parentRecurringTaskId ?? this.parentRecurringTaskId,
      isRecurringInstance: isRecurringInstance ?? this.isRecurringInstance,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
    );
  }

  @override
  String toString() {
    return 'Task{id: $id, title: $title, isCompleted: $isCompleted, priority: $priority, category: $category, recurrenceType: $recurrenceType, recurrenceInterval: $recurrenceInterval, recurrenceEndDate: $recurrenceEndDate, parentRecurringTaskId: $parentRecurringTaskId, isRecurringInstance: $isRecurringInstance}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
