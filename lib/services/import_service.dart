import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/category.dart' as models;
import '../utils/app_utils.dart';

enum ImportMode {
  merge,
  replace,
}

class ImportValidationError {
  final String message;
  final int? index;

  ImportValidationError(this.message, {this.index});

  @override
  String toString() =>
      index != null ? '$message (at index $index)' : message;
}

class ImportPreview {
  final int totalTasks;
  final int totalCategories;
  final int newTasks;
  final int existingTasks;
  final int newCategories;
  final String version;
  final DateTime exportDate;
  final List<ImportValidationError> warnings;

  ImportPreview({
    required this.totalTasks,
    required this.totalCategories,
    required this.newTasks,
    required this.existingTasks,
    required this.newCategories,
    required this.version,
    required this.exportDate,
    this.warnings = const [],
  });
}

class ImportResult {
  final bool success;
  final String? error;
  final int tasksImported;
  final int categoriesImported;
  final int tasksSkipped;
  final List<String> errors;

  ImportResult({
    required this.success,
    this.error,
    this.tasksImported = 0,
    this.categoriesImported = 0,
    this.tasksSkipped = 0,
    this.errors = const [],
  });
}

class ImportService {
  static final ImportService _instance = ImportService._internal();
  factory ImportService() => _instance;
  ImportService._internal();

  Future<ImportPreview> previewImport({
    required String jsonContent,
    required List<Task> existingTasks,
    required List<models.Category> existingCategories,
  }) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;

      _validateStructure(data);

      final version = data['version'] as String;
      final exportDate = DateTime.parse(data['exportDate'] as String);
      final tasks = (data['tasks'] as List).cast<Map<String, dynamic>>();
      final categories =
          (data['categories'] as List).cast<Map<String, dynamic>>();

      final existingTaskIds = existingTasks.map((t) => t.id).toSet();
      final existingCategoryNames =
          existingCategories.map((c) => c.name).toSet();

      final newTasks =
          tasks.where((t) => !existingTaskIds.contains(t['id'])).length;
      final newCategories = categories
          .where((c) => !existingCategoryNames.contains(c['name']))
          .length;

      final warnings = <ImportValidationError>[];
      for (var i = 0; i < tasks.length; i++) {
        final taskWarnings = _validateTask(tasks[i], i);
        warnings.addAll(taskWarnings);
      }

      return ImportPreview(
        totalTasks: tasks.length,
        totalCategories: categories.length,
        newTasks: newTasks,
        existingTasks: tasks.length - newTasks,
        newCategories: newCategories,
        version: version,
        exportDate: exportDate,
        warnings: warnings,
      );
    } catch (e) {
      debugPrint('Preview error: $e');
      rethrow;
    }
  }

  Future<ImportResult> importFromJson({
    required String jsonContent,
    required ImportMode mode,
    required List<Task> existingTasks,
    required List<models.Category> existingCategories,
  }) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;

      _validateStructure(data);
      _validateVersion(data['version'] as String);

      final tasks = (data['tasks'] as List).cast<Map<String, dynamic>>();
      final categories =
          (data['categories'] as List).cast<Map<String, dynamic>>();

      final importedTasks = <Task>[];
      final importedCategories = <models.Category>[];
      final errors = <String>[];
      var skipped = 0;

      for (var i = 0; i < categories.length; i++) {
        try {
          final category = categoryFromJson(categories[i]);
          
          if (mode == ImportMode.merge) {
            final exists = existingCategories.any((c) => c.name == category.name);
            if (exists) {
              skipped++;
              continue;
            }
          }
          
          importedCategories.add(category);
        } catch (e) {
          errors.add('Category at index $i: $e');
          debugPrint('Error importing category $i: $e');
        }
      }

      for (var i = 0; i < tasks.length; i++) {
        try {
          final task = taskFromJson(tasks[i]);
          
          if (mode == ImportMode.merge) {
            final exists = existingTasks.any((t) => t.id == task.id);
            if (exists) {
              skipped++;
              continue;
            }
          }
          
          importedTasks.add(task);
        } catch (e) {
          errors.add('Task at index $i: $e');
          debugPrint('Error importing task $i: $e');
        }
      }

      debugPrint(
        'Import completed: ${importedTasks.length} tasks, ${importedCategories.length} categories, $skipped skipped',
      );

      return ImportResult(
        success: true,
        tasksImported: importedTasks.length,
        categoriesImported: importedCategories.length,
        tasksSkipped: skipped,
        errors: errors,
      );
    } catch (e) {
      debugPrint('Import error: $e');
      return ImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> parseJsonFile(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error reading file: $e');
      rethrow;
    }
  }

  void _validateStructure(Map<String, dynamic> data) {
    final requiredFields = ['version', 'exportDate', 'tasks', 'categories'];
    
    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        throw Exception('Missing required field: $field');
      }
    }

    if (data['tasks'] is! List) {
      throw Exception('Invalid format: tasks must be a list');
    }

    if (data['categories'] is! List) {
      throw Exception('Invalid format: categories must be a list');
    }
  }

  void _validateVersion(String version) {
    final supportedVersions = ['1.0'];
    if (!supportedVersions.contains(version)) {
      throw Exception('Unsupported version: $version');
    }
  }

  List<ImportValidationError> _validateTask(
    Map<String, dynamic> taskData,
    int index,
  ) {
    final errors = <ImportValidationError>[];

    if (!taskData.containsKey('id') || taskData['id'] == null) {
      errors.add(
        ImportValidationError('Missing required field: id', index: index),
      );
    }

    if (!taskData.containsKey('title') ||
        taskData['title'] == null ||
        (taskData['title'] as String).isEmpty) {
      errors.add(
        ImportValidationError('Missing or empty title', index: index),
      );
    }

    if (taskData.containsKey('priority')) {
      try {
        _parsePriority(taskData['priority'] as String);
      } catch (e) {
        errors.add(
          ImportValidationError('Invalid priority value', index: index),
        );
      }
    }

    if (taskData.containsKey('dueDate') && taskData['dueDate'] != null) {
      try {
        DateTime.parse(taskData['dueDate'] as String);
      } catch (e) {
        errors.add(
          ImportValidationError('Invalid dueDate format', index: index),
        );
      }
    }

    return errors;
  }

  Task taskFromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      priority: _parsePriority(json['priority'] as String? ?? 'medium'),
      category: json['category'] as String? ?? AppConstants.defaultCategory,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      hasNotification: json['hasNotification'] as bool? ?? false,
    );
  }

  models.Category categoryFromJson(Map<String, dynamic> json) {
    return models.Category(
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
    );
  }

  TaskPriority _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'medium':
        return TaskPriority.medium;
      case 'high':
        return TaskPriority.high;
      default:
        return TaskPriority.medium;
    }
  }
}
