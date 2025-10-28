import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'subtask.dart';

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
  List<Subtask> subtasks;

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
    List<Subtask>? subtasks,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        subtasks = List<Subtask>.from(subtasks ?? const []);

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
    List<Subtask>? subtasks,
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
      subtasks: subtasks != null
          ? List<Subtask>.from(subtasks)
          : List<Subtask>.from(this.subtasks),
    );
  }

  int get completedSubtasksCount =>
      subtasks.where((subtask) => subtask.isCompleted).length;

  int get totalSubtasksCount => subtasks.length;

  double get subtaskCompletionPercentage => totalSubtasksCount == 0
      ? 0
      : (completedSubtasksCount / totalSubtasksCount) * 100;

  bool get hasSubtasks => subtasks.isNotEmpty;

  @override
  String toString() {
    return 'Task{id: $id, title: $title, isCompleted: $isCompleted, priority: $priority, category: $category, subtasks: ${subtasks.length}}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
