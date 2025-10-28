import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/task.dart';
import '../models/category.dart' as models;
import '../utils/app_utils.dart';

class ExportResult {
  final bool success;
  final String? filePath;
  final String? error;
  final int taskCount;
  final int categoryCount;

  ExportResult({
    required this.success,
    this.filePath,
    this.error,
    this.taskCount = 0,
    this.categoryCount = 0,
  });
}

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  Future<ExportResult> exportToJson({
    required List<Task> tasks,
    required List<models.Category> categories,
    bool includeCompleted = true,
    bool includeSettings = false,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final tasksToExport = includeCompleted
          ? tasks
          : tasks.where((task) => !task.isCompleted).toList();

      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toUtc().toIso8601String(),
        'appVersion': AppConstants.appVersion,
        'schemaVersion': AppConstants.currentSchemaVersion,
        'taskCount': tasksToExport.length,
        'categoryCount': categories.length,
        'tasks': tasksToExport.map((task) => _taskToJson(task)).toList(),
        'categories':
            categories.map((cat) => _categoryToJson(cat)).toList(),
      };

      if (includeSettings && settings != null) {
        exportData['settings'] = settings;
      }

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      final file = await _saveToFile(jsonString);

      debugPrint('Export successful: ${file.path}');
      return ExportResult(
        success: true,
        filePath: file.path,
        taskCount: tasksToExport.length,
        categoryCount: categories.length,
      );
    } catch (e) {
      debugPrint('Export error: $e');
      return ExportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<File> _saveToFile(String jsonString) async {
    final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final filename = 'dooit_backup_$timestamp.json';

    Directory directory;
    if (kIsWeb) {
      throw UnsupportedError('File saving not supported on web');
    } else if (Platform.isAndroid) {
      directory = await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      final docsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${docsDir.path}/DoIt/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      directory = backupDir;
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final file = File('${directory.path}/$filename');
    await file.writeAsString(jsonString);

    return file;
  }

  Future<void> shareExportFile(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'DoIt Backup - ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      );
    } catch (e) {
      debugPrint('Share error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _taskToJson(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'dueDate': task.dueDate?.toIso8601String(),
      'priority': task.priority.name,
      'category': task.category,
      'isCompleted': task.isCompleted,
      'createdAt': task.createdAt.toIso8601String(),
      'completedAt': task.completedAt?.toIso8601String(),
      'hasNotification': task.hasNotification,
    };
  }

  Map<String, dynamic> _categoryToJson(models.Category category) {
    return {
      'name': category.name,
      'colorValue': category.colorValue,
    };
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
