import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/migration_service.dart';
import '../models/task.dart';
import '../models/category.dart' as models;

class Migration1To2 extends Migration {
  @override
  int get fromVersion => 1;

  @override
  int get toVersion => 2;

  @override
  String get description => 'Add tags field to tasks and icon field to categories';

  @override
  Future<void> migrate(Box tasksBox, Box categoriesBox) async {
    try {
      debugPrint('Starting migration 1 -> 2');
      debugPrint('Tasks to migrate: ${tasksBox.length}');
      debugPrint('Categories to migrate: ${categoriesBox.length}');

      await _migrateTasksBox(tasksBox);
      await _migrateCategoriesBox(categoriesBox);

      debugPrint('Migration 1 -> 2 completed successfully');
    } catch (e) {
      debugPrint('Error in migration 1 -> 2: $e');
      rethrow;
    }
  }

  Future<void> _migrateTasksBox(Box tasksBox) async {
    int migratedCount = 0;
    int errorCount = 0;

    for (int i = 0; i < tasksBox.length; i++) {
      try {
        final task = tasksBox.getAt(i);
        
        if (task == null) {
          debugPrint('Null task at index $i, skipping');
          continue;
        }

        if (task is! Task) {
          debugPrint('Invalid task type at index $i: ${task.runtimeType}');
          errorCount++;
          continue;
        }

        migratedCount++;
      } catch (e) {
        debugPrint('Error processing task at index $i: $e');
        errorCount++;
      }
    }

    debugPrint('Tasks migrated: $migratedCount, errors: $errorCount');
  }

  Future<void> _migrateCategoriesBox(Box categoriesBox) async {
    int migratedCount = 0;
    int errorCount = 0;

    for (int i = 0; i < categoriesBox.length; i++) {
      try {
        final category = categoriesBox.getAt(i);
        
        if (category == null) {
          debugPrint('Null category at index $i, skipping');
          continue;
        }

        if (category is! models.Category) {
          debugPrint('Invalid category type at index $i: ${category.runtimeType}');
          errorCount++;
          continue;
        }

        migratedCount++;
      } catch (e) {
        debugPrint('Error processing category at index $i: $e');
        errorCount++;
      }
    }

    debugPrint('Categories migrated: $migratedCount, errors: $errorCount');
  }
}
