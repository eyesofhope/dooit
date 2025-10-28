import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

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
}
