import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/category.dart' as models;
import '../models/app_settings.dart';
import '../utils/app_utils.dart';

enum BackupType {
  manual,
  automatic,
}

class BackupInfo {
  final String path;
  final String filename;
  final DateTime createdAt;
  final int fileSize;
  final int taskCount;
  final BackupType type;

  BackupInfo({
    required this.path,
    required this.filename,
    required this.createdAt,
    required this.fileSize,
    required this.taskCount,
    required this.type,
  });

  String get formattedDate => DateFormat('MMM dd, yyyy HH:mm').format(createdAt);

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  Future<String> createBackup(List<String> boxNames) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDocDir.path}/backups');
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupPath = '${backupDir.path}/backup_$timestamp';
      final backupFolder = Directory(backupPath);
      await backupFolder.create();

      for (final boxName in boxNames) {
        try {
          final box = await Hive.openBox(boxName);
          final boxPath = box.path;
          
          if (boxPath != null && await File(boxPath).exists()) {
            final backupFile = File('$backupPath/$boxName.hive');
            await File(boxPath).copy(backupFile.path);
            debugPrint('Backed up box: $boxName');
          }
        } catch (e) {
          debugPrint('Error backing up box $boxName: $e');
        }
      }

      debugPrint('Backup created at: $backupPath');
      return backupPath;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      rethrow;
    }
  }

  Future<void> restoreBackup(String backupPath, List<String> boxNames) async {
    try {
      final backupDir = Directory(backupPath);
      
      if (!await backupDir.exists()) {
        throw Exception('Backup directory not found: $backupPath');
      }

      for (final boxName in boxNames) {
        try {
          final backupFile = File('$backupPath/$boxName.hive');
          
          if (await backupFile.exists()) {
            final box = await Hive.openBox(boxName);
            await box.close();

            final boxPath = Hive.isBoxOpen(boxName) 
                ? Hive.box(boxName).path 
                : '${(await getApplicationDocumentsDirectory()).path}/$boxName.hive';
            
            if (boxPath != null) {
              await backupFile.copy(boxPath);
              debugPrint('Restored box: $boxName');
            }

            await Hive.openBox(boxName);
          }
        } catch (e) {
          debugPrint('Error restoring box $boxName: $e');
        }
      }

      debugPrint('Backup restored from: $backupPath');
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      rethrow;
    }
  }

  Future<void> deleteBackup(String backupPath) async {
    try {
      final backupDir = Directory(backupPath);
      
      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
        debugPrint('Deleted backup: $backupPath');
      }
    } catch (e) {
      debugPrint('Error deleting backup: $e');
    }
  }

  Future<List<String>> listBackups() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDocDir.path}/backups');
      
      if (!await backupDir.exists()) {
        return [];
      }

      final backups = await backupDir
          .list()
          .where((entity) => entity is Directory)
          .map((entity) => entity.path)
          .toList();
      
      return backups;
    } catch (e) {
      debugPrint('Error listing backups: $e');
      return [];
    }
  }

  Future<void> cleanOldBackups({int keepLast = 5}) async {
    try {
      final backups = await listBackups();
      
      if (backups.length > keepLast) {
        backups.sort();
        final backupsToDelete = backups.take(backups.length - keepLast);
        
        for (final backup in backupsToDelete) {
          await deleteBackup(backup);
        }
        
        debugPrint('Cleaned ${backupsToDelete.length} old backups');
      }
    } catch (e) {
      debugPrint('Error cleaning old backups: $e');
    }
  }

  Future<String> createJsonBackup({
    required List<Task> tasks,
    required List<models.Category> categories,
    required BackupType type,
    bool includeCompleted = true,
  }) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDocDir.path}/backups');
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final prefix = type == BackupType.automatic ? 'auto' : 'manual';
      final filename = 'dooit_${prefix}_backup_$timestamp.json';

      final tasksToBackup = includeCompleted
          ? tasks
          : tasks.where((task) => !task.isCompleted).toList();

      final backupData = {
        'version': '1.0',
        'exportDate': DateTime.now().toUtc().toIso8601String(),
        'appVersion': AppConstants.appVersion,
        'schemaVersion': AppConstants.currentSchemaVersion,
        'backupType': type.name,
        'taskCount': tasksToBackup.length,
        'categoryCount': categories.length,
        'tasks': tasksToBackup.map(_taskToJson).toList(),
        'categories': categories.map(_categoryToJson).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final file = File('${backupDir.path}/$filename');
      await file.writeAsString(jsonString);

      debugPrint('JSON backup created: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('Error creating JSON backup: $e');
      rethrow;
    }
  }

  Future<List<BackupInfo>> listJsonBackups() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDocDir.path}/backups');
      
      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      final backups = <BackupInfo>[];

      for (final file in files) {
        try {
          final stat = await file.stat();
          final content = await file.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;
          
          final filename = file.path.split('/').last;
          final type = filename.contains('_auto_')
              ? BackupType.automatic
              : BackupType.manual;

          backups.add(
            BackupInfo(
              path: file.path,
              filename: filename,
              createdAt: stat.modified,
              fileSize: stat.size,
              taskCount: data['taskCount'] as int? ?? 0,
              type: type,
            ),
          );
        } catch (e) {
          debugPrint('Error reading backup file ${file.path}: $e');
        }
      }

      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return backups;
    } catch (e) {
      debugPrint('Error listing JSON backups: $e');
      return [];
    }
  }

  Future<void> deleteJsonBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted JSON backup: $backupPath');
      }
    } catch (e) {
      debugPrint('Error deleting JSON backup: $e');
      rethrow;
    }
  }

  Future<void> cleanOldJsonBackups({
    required int keepLast,
    BackupType? type,
  }) async {
    try {
      var backups = await listJsonBackups();
      
      if (type != null) {
        backups = backups.where((b) => b.type == type).toList();
      }

      if (backups.length > keepLast) {
        final toDelete = backups.skip(keepLast).toList();
        
        for (final backup in toDelete) {
          await deleteJsonBackup(backup.path);
        }
        
        debugPrint('Cleaned ${toDelete.length} old JSON backups');
      }
    } catch (e) {
      debugPrint('Error cleaning old JSON backups: $e');
    }
  }

  Future<bool> shouldCreateAutomaticBackup(AppSettings settings) async {
    if (!settings.automaticBackupsEnabled) {
      return false;
    }

    if (settings.lastBackupAt == null) {
      return true;
    }

    final now = DateTime.now();
    final lastBackup = settings.lastBackupAt!;

    switch (settings.backupFrequency) {
      case BackupFrequency.daily:
        return now.difference(lastBackup).inDays >= 1;
      case BackupFrequency.weekly:
        return now.difference(lastBackup).inDays >= 7;
    }
  }

  Future<Map<String, dynamic>> readBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error reading backup file: $e');
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
}
