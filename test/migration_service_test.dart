import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dooit/models/app_version.dart';
import 'package:dooit/models/task.dart';
import 'package:dooit/models/category.dart' as models;
import 'package:dooit/services/migration_service.dart';
import 'package:dooit/utils/app_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hive.init('./test/hive_test_data');
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(TaskPriorityAdapter());
    Hive.registerAdapter(models.CategoryAdapter());
    Hive.registerAdapter(AppVersionAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('MigrationService Tests', () {
    late MigrationService migrationService;

    setUp(() async {
      migrationService = MigrationService();
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
    });

    test('should return version 0 for new installation', () async {
      final version = await migrationService.getCurrentSchemaVersion();
      expect(version, equals(0));
    });

    test('should initialize version on first launch', () async {
      await migrationService.initializeVersion();
      final version = await migrationService.getCurrentSchemaVersion();
      expect(version, equals(AppConstants.currentSchemaVersion));
    });

    test('should update schema version', () async {
      await migrationService.initializeVersion();
      await migrationService.updateSchemaVersion(2);
      final version = await migrationService.getCurrentSchemaVersion();
      expect(version, equals(2));
    });

    test('should detect when migration is needed', () async {
      await migrationService.initializeVersion();
      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      final oldVersion = AppVersion(
        schemaVersion: 0,
        lastMigrationDate: DateTime.now(),
        appVersion: '1.0.0',
      );
      await versionBox.clear();
      await versionBox.add(oldVersion);

      final needsMigration = await migrationService.needsMigration();
      expect(needsMigration, isTrue);
    });

    test('should not run migration when not needed', () async {
      await migrationService.initializeVersion();
      final result = await migrationService.runMigrations();
      
      expect(result.success, isTrue);
      expect(result.message, contains('No migration needed'));
      expect(result.migratedFrom, equals(AppConstants.currentSchemaVersion));
      expect(result.migratedTo, equals(AppConstants.currentSchemaVersion));
    });

    test('should handle first installation without migration', () async {
      final result = await migrationService.runMigrations();
      
      expect(result.success, isTrue);
      expect(result.migratedFrom, equals(0));
      expect(result.migratedTo, equals(AppConstants.currentSchemaVersion));
    });

    test('should call onProgress callback during migration', () async {
      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      final oldVersion = AppVersion(
        schemaVersion: 0,
        lastMigrationDate: DateTime.now(),
        appVersion: '1.0.0',
      );
      await versionBox.add(oldVersion);

      final progressUpdates = <String>[];
      await migrationService.runMigrations(
        onProgress: (status) => progressUpdates.add(status),
      );

      expect(progressUpdates, isNotEmpty);
      expect(progressUpdates.first, contains('backup'));
    });

    test('should migrate tasks and categories successfully', () async {
      final tasksBox = await Hive.openBox<Task>(AppConstants.tasksBoxName);
      final categoriesBox = await Hive.openBox<models.Category>(
        AppConstants.categoriesBoxName,
      );

      final task = Task(
        title: 'Test Task',
        description: 'Test Description',
        priority: TaskPriority.high,
        category: 'Work',
      );
      await tasksBox.add(task);

      final category = models.Category(
        name: 'Work',
        colorValue: 0xFF2196F3,
      );
      await categoriesBox.add(category);

      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      final oldVersion = AppVersion(
        schemaVersion: 0,
        lastMigrationDate: DateTime.now(),
        appVersion: '1.0.0',
      );
      await versionBox.add(oldVersion);

      final result = await migrationService.runMigrations();
      
      expect(result.success, isTrue);
      expect(tasksBox.length, equals(1));
      expect(categoriesBox.length, equals(1));
    });

    test('should preserve data integrity after migration', () async {
      final tasksBox = await Hive.openBox<Task>(AppConstants.tasksBoxName);
      
      final task = Task(
        title: 'Important Task',
        description: 'Do not lose this',
        priority: TaskPriority.high,
        category: 'Personal',
        dueDate: DateTime(2024, 12, 31),
      );
      await tasksBox.add(task);

      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      final oldVersion = AppVersion(
        schemaVersion: 0,
        lastMigrationDate: DateTime.now(),
        appVersion: '1.0.0',
      );
      await versionBox.add(oldVersion);

      await migrationService.runMigrations();

      final migratedTask = tasksBox.getAt(0) as Task;
      expect(migratedTask.title, equals('Important Task'));
      expect(migratedTask.description, equals('Do not lose this'));
      expect(migratedTask.priority, equals(TaskPriority.high));
      expect(migratedTask.category, equals('Personal'));
      expect(migratedTask.dueDate?.year, equals(2024));
    });

    test('should handle empty boxes during migration', () async {
      await Hive.openBox<Task>(AppConstants.tasksBoxName);
      await Hive.openBox<models.Category>(AppConstants.categoriesBoxName);

      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      final oldVersion = AppVersion(
        schemaVersion: 0,
        lastMigrationDate: DateTime.now(),
        appVersion: '1.0.0',
      );
      await versionBox.add(oldVersion);

      final result = await migrationService.runMigrations();
      
      expect(result.success, isTrue);
    });

    test('should handle multiple tasks during migration', () async {
      final tasksBox = await Hive.openBox<Task>(AppConstants.tasksBoxName);
      
      for (int i = 0; i < 10; i++) {
        await tasksBox.add(Task(
          title: 'Task $i',
          description: 'Description $i',
          priority: TaskPriority.values[i % 3],
        ));
      }

      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      final oldVersion = AppVersion(
        schemaVersion: 0,
        lastMigrationDate: DateTime.now(),
        appVersion: '1.0.0',
      );
      await versionBox.add(oldVersion);

      final result = await migrationService.runMigrations();
      
      expect(result.success, isTrue);
      expect(tasksBox.length, equals(10));
    });

    test('should update version after successful migration', () async {
      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      final oldVersion = AppVersion(
        schemaVersion: 0,
        lastMigrationDate: DateTime.now(),
        appVersion: '1.0.0',
      );
      await versionBox.add(oldVersion);

      await migrationService.runMigrations();

      final newVersion = await migrationService.getCurrentSchemaVersion();
      expect(newVersion, equals(AppConstants.currentSchemaVersion));
    });
  });

  group('MigrationResult Tests', () {
    test('should create successful migration result', () {
      final result = MigrationResult(
        success: true,
        message: 'Migration successful',
        migratedFrom: 1,
        migratedTo: 2,
        migrationsRun: ['Test Migration'],
      );

      expect(result.success, isTrue);
      expect(result.message, equals('Migration successful'));
      expect(result.migratedFrom, equals(1));
      expect(result.migratedTo, equals(2));
      expect(result.migrationsRun, contains('Test Migration'));
    });

    test('should create failed migration result', () {
      final result = MigrationResult(
        success: false,
        message: 'Migration failed',
        migratedFrom: 1,
        migratedTo: 1,
        error: 'Test error',
      );

      expect(result.success, isFalse);
      expect(result.error, equals('Test error'));
    });
  });

  group('MigrationException Tests', () {
    test('should create exception with message', () {
      final exception = MigrationException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.toString(), contains('Test error'));
    });
  });
}
