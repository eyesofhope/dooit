import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dooit/models/task.dart';
import 'package:dooit/services/backup_service.dart';
import 'package:dooit/utils/app_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hive.init('./test/hive_backup_test_data');
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(TaskPriorityAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('BackupService Tests', () {
    late BackupService backupService;

    setUp(() async {
      backupService = BackupService();
      
      await Hive.deleteBoxFromDisk(AppConstants.tasksBoxName);
    });

    tearDown(() async {
      if (Hive.isBoxOpen(AppConstants.tasksBoxName)) {
        await Hive.box(AppConstants.tasksBoxName).close();
      }
      
      final backups = await backupService.listBackups();
      for (final backup in backups) {
        await backupService.deleteBackup(backup);
      }
    });

    test('should create backup successfully', () async {
      final tasksBox = await Hive.openBox<Task>(AppConstants.tasksBoxName);
      await tasksBox.add(Task(title: 'Test Task'));

      final backupPath = await backupService.createBackup([
        AppConstants.tasksBoxName,
      ]);

      expect(backupPath, isNotEmpty);
      expect(Directory(backupPath).existsSync(), isTrue);
    });

    test('should list backups', () async {
      final tasksBox = await Hive.openBox<Task>(AppConstants.tasksBoxName);
      await tasksBox.add(Task(title: 'Test Task'));

      await backupService.createBackup([AppConstants.tasksBoxName]);
      await backupService.createBackup([AppConstants.tasksBoxName]);

      final backups = await backupService.listBackups();
      expect(backups.length, greaterThanOrEqualTo(2));
    });

    test('should delete backup', () async {
      final tasksBox = await Hive.openBox<Task>(AppConstants.tasksBoxName);
      await tasksBox.add(Task(title: 'Test Task'));

      final backupPath = await backupService.createBackup([
        AppConstants.tasksBoxName,
      ]);
      
      expect(Directory(backupPath).existsSync(), isTrue);

      await backupService.deleteBackup(backupPath);
      expect(Directory(backupPath).existsSync(), isFalse);
    });

    test('should clean old backups', () async {
      final tasksBox = await Hive.openBox<Task>(AppConstants.tasksBoxName);
      await tasksBox.add(Task(title: 'Test Task'));

      for (int i = 0; i < 7; i++) {
        await backupService.createBackup([AppConstants.tasksBoxName]);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await backupService.cleanOldBackups(keepLast: 3);

      final backups = await backupService.listBackups();
      expect(backups.length, lessThanOrEqualTo(3));
    });

    test('should handle empty box during backup', () async {
      await Hive.openBox<Task>(AppConstants.tasksBoxName);

      final backupPath = await backupService.createBackup([
        AppConstants.tasksBoxName,
      ]);

      expect(backupPath, isNotEmpty);
    });

    test('should handle multiple boxes in single backup', () async {
      await Hive.openBox<Task>(AppConstants.tasksBoxName);
      await Hive.openBox(AppConstants.categoriesBoxName);

      final backupPath = await backupService.createBackup([
        AppConstants.tasksBoxName,
        AppConstants.categoriesBoxName,
      ]);

      expect(backupPath, isNotEmpty);
      expect(Directory(backupPath).existsSync(), isTrue);

      if (Hive.isBoxOpen(AppConstants.categoriesBoxName)) {
        await Hive.box(AppConstants.categoriesBoxName).close();
      }
    });
  });
}
