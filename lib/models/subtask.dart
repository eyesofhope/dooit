import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'subtask.g.dart';

@HiveType(typeId: 6)
class Subtask extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime? completedAt;

  @HiveField(5)
  int order;

  Subtask({
    String? id,
    required this.title,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
    this.order = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Subtask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    int? order,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      order: order ?? this.order,
    );
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subtask && other.id == id;
  }

  @override
  String toString() {
    return 'Subtask{id: $id, title: $title, isCompleted: $isCompleted, order: $order}';
  }
}
