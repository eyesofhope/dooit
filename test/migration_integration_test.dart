import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dooit/models/app_version.dart';
import 'package:dooit/models/task.dart';
import 'package:dooit/models/category.dart' as models;
import 'package:dooit/services/migration_service.dart';
import 'package:dooit/services/backup_service.dart';
import 'package:dooit/utils/app_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hive.init('./test/hive_integration_test_data');
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(TaskPriorityAdapter());
    Hive.registerAdapter(models.CategoryAdapter());
    Hive.registerAdapter(AppVersionAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('Migration Integration Tests', () {
    late MigrationService migrationService;
    late BackupService backupService;

    setUp(() async {
      migrationService = MigrationService();
      backupService = BackupService();
      migrationService.registerMigrations();

      await Hive.deleteBoxFromDisk(AppConstants.versionBoxName);
      await Hive.deleteBoxFromDisk(AppConstants.tasksBoxName);
      await Hive.deleteBoxFromDisk(AppConstants.categoriesBoxName);
    });

    tearDown(() async {
      if (Hive.isBoxOpen(AppConstants.versionBoxName)) {
        await Hive.box(AppConstants.versionBoxName).close();
      }
      if (Hive.isBoxOpen(AppConstants.tasksBoxName)) {
        await Hive.box(AppConstants.tasksBoxName).close();
      }
      if (Hive.isBoxOpen(AppConstants.categoriesBoxName)) {
        await Hive.box(AppConstants.categoriesBoxName).close();
      }

      final backups = await backupService.listBackups();
      for (final backup in backups) {
        await backupService.deleteBackup(backup);
      }
    });

    test('complete app initialization flow for new user', () async {
      final currentVersion = await migrationService.getCurrentSchemaVersion();
      expect(currentVersion, equals(0));

      await migrationService.initializeVersion();

      final updatedVersion = await migrationService.getCurrentSchemaVersion();
      expect(updatedVersion, equals(AppConstants.currentSchemaVersion));

      final needsMigration = await migrationService.needsMigration();
      expect(needsMigration, isFalse);
    });

    test('complete app initialization flow for existing user', () async {
      final tasksBox = await Hive.openBox<Task>(AppConstants.tasksBoxName);
      final categoriesBox = await Hive.openBox<models.Category>(
        AppConstants.categoriesBoxName,
      );

      await tasksBox.add(Task(
        title: 'Existing Task',
        description: 'User created this before update',
        priority: TaskPriority.high,
        category: 'Work',
      ));

      await categoriesBox.add(models.Category(
        name: 'Work',
        colorValue: 0xFF2196F3,
      ));

      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      await versionBox.add(AppVersion(
        schemaVersion: 0,
        lastMigrationDate: DateTime.now().subtract(const Duration(days: 30)),
        appVersion: '0.9.0',
      ));

      final result = await migrationService.runMigrations();

      expect(result.success, isTrue);
      expect(result.migratedFrom, equals(0));
      expect(result.migratedTo, equals(AppConstants.currentSchemaVersion));

      final migratedTask = tasksBox.getAt(0) as Task;
      expect(migratedTask.title, equals('Existing Task'));
      expect(migratedTask.description, equals('User created this before update'));
      expect(migratedTask.priority, equals(TaskPriority.high));

      final migratedCategory = categoriesBox.getAt(0) as models.Category;
      expect(migratedCategory.name, equals('Work'));
    });

    test('migration creates backup before running', () async {
      final tasksBox = await Hive.openBox<Task>(AppConstants.tasksBoxName);
      await tasksBox.add(Task(title: 'Important Data'));

      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      await versionBox.add(AppVersion(
        schemaVersion: 0,
        lastMigrationDate: DateTime.now(),
        appVersion: '1.0.0',
      ));

      final initialBackups = await backupService.listBackups();
      final initialCount = initialBackups.length;

      await migrationService.runMigrations();

      final finalBackups = await backupService.listBackups();
      expect(finalBackups.length, greaterThan(initialCount));
    });

    test('migration preserves all task properties', () async {
      final tasksBox = await Hive.openBox<Task>(AppConstants.tasksBoxName);
      final now = DateTime.now();
      final dueDate = now.add(const Duration(days: 7));

      final task = Task(
        title: 'Complex Task',
        description: 'With all properties set',
        priority: TaskPriority.high,
        category: 'Personal',
        dueDate: dueDate,
        hasNotification: true,
        isCompleted: false,
        createdAt: now,
      );
      await tasksBox.add(task);

      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      await versionBox.add(AppVersion(
        schemaVersion: 0,
        lastMigrationDate: DateTime.now(),
        appVersion: '1.0.0',
      ));

      await migrationService.runMigrations();

      final migratedTask = tasksBox.getAt(0) as Task;
      expect(migratedTask.title, equals('Complex Task'));
      expect(migratedTask.description, equals('With all properties set'));
      expect(migratedTask.priority, equals(TaskPriority.high));
      expect(migratedTask.category, equals('Personal'));
      expect(migratedTask.hasNotification, isTrue);
      expect(migratedTask.isCompleted, isFalse);
      expect(migratedTask.dueDate?.day, equals(dueDate.day));
    });

    test('migration handles multiple categories correctly', () async {
      final categoriesBox = await Hive.openBox<models.Category>(
        AppConstants.categoriesBoxName,
      );

      final categories = [
        models.Category(name: 'Work', colorValue: 0xFF2196F3),
        models.Category(name: 'Personal', colorValue: 0xFF4CAF50),
        models.Category(name: 'Shopping', colorValue: 0xFF9C27B0),
      ];

      for (final category in categories) {
        await categoriesBox.add(category);
      }

      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      await versionBox.add(AppVersion(
        schemaVersion: 0,
        lastMigrationDate: DateTime.now(),
        appVersion: '1.0.0',
      ));

      await migrationService.runMigrations();

      expect(categoriesBox.length, equals(3));
      
      final workCategory = categoriesBox.getAt(0) as models.Category;
      expect(workCategory.name, equals('Work'));
      
      final personalCategory = categoriesBox.getAt(1) as models.Category;
      expect(personalCategory.name, equals('Personal'));
      
      final shoppingCategory = categoriesBox.getAt(2) as models.Category;
      expect(shoppingCategory.name, equals('Shopping'));
    });

    test('migration updates version info correctly', () async {
      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      final oldDate = DateTime.now().subtract(const Duration(days: 30));
      
      await versionBox.add(AppVersion(
        schemaVersion: 0,
        lastMigrationDate: oldDate,
        appVersion: '0.9.0',
      ));

      await migrationService.runMigrations();

      final updatedVersion = versionBox.getAt(0) as AppVersion;
      expect(updatedVersion.schemaVersion, equals(AppConstants.currentSchemaVersion));
      expect(updatedVersion.appVersion, equals(AppConstants.appVersion));
      expect(updatedVersion.lastMigrationDate.isAfter(oldDate), isTrue);
    });

    test('no migration needed when already up to date', () async {
      await migrationService.initializeVersion();

      final needsMigration = await migrationService.needsMigration();
      expect(needsMigration, isFalse);

      final result = await migrationService.runMigrations();
      expect(result.success, isTrue);
      expect(result.message, contains('No migration needed'));
    });

    test('migration with large dataset', () async {
      final tasksBox = await Hive.openBox<Task>(AppConstants.tasksBoxName);

      for (int i = 0; i < 100; i++) {
        await tasksBox.add(Task(
          title: 'Task $i',
          description: 'Description for task $i',
          priority: TaskPriority.values[i % 3],
          category: ['Work', 'Personal', 'Shopping'][i % 3],
        ));
      }

      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      await versionBox.add(AppVersion(
        schemaVersion: 0,
        lastMigrationDate: DateTime.now(),
        appVersion: '1.0.0',
      ));

      final result = await migrationService.runMigrations();

      expect(result.success, isTrue);
      expect(tasksBox.length, equals(100));

      for (int i = 0; i < 100; i++) {
        final task = tasksBox.getAt(i) as Task;
        expect(task.title, equals('Task $i'));
      }
    });

    test('progress callback receives updates', () async {
      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      await versionBox.add(AppVersion(
        schemaVersion: 0,
        lastMigrationDate: DateTime.now(),
        appVersion: '1.0.0',
      ));

      final progressUpdates = <String>[];
      
      await migrationService.runMigrations(
        onProgress: (status) {
          progressUpdates.add(status);
        },
      );

      expect(progressUpdates, isNotEmpty);
      expect(progressUpdates.any((s) => s.contains('backup')), isTrue);
      expect(progressUpdates.any((s) => s.contains('complete')), isTrue);
    });
  });
}
