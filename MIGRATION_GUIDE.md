# Data Migration System Guide

This guide explains how to use and extend the data migration system in the DoIt application.

## Overview

The data migration system provides a robust framework for handling schema changes to Task and Category models, ensuring smooth upgrades for existing users. It includes:

- **Version tracking**: Tracks the current schema version in Hive
- **Automatic backups**: Creates backups before running migrations
- **Rollback support**: Restores backups if migrations fail
- **Progress notifications**: Shows migration status to users
- **Sequential migrations**: Runs migrations in order (v1→v2→v3...)

## Architecture

### Key Components

1. **AppVersion Model** (`lib/models/app_version.dart`)
   - Stores schema version, last migration date, and app version
   - Persisted in Hive box

2. **MigrationService** (`lib/services/migration_service.dart`)
   - Singleton service that manages migrations
   - Registers and executes migrations
   - Handles version tracking and error recovery

3. **BackupService** (`lib/services/backup_service.dart`)
   - Creates timestamped backups of Hive boxes
   - Restores backups on migration failure
   - Manages backup cleanup (keeps last 5 by default)

4. **Migration Interface** (`lib/services/migration_service.dart`)
   ```dart
   abstract class Migration {
     int get fromVersion;
     int get toVersion;
     String get description;
     Future<void> migrate(Box tasksBox, Box categoriesBox);
   }
   ```

5. **Sample Migration** (`lib/migrations/migration_1_to_2.dart`)
   - Example migration showing the pattern
   - Demonstrates data validation and transformation

## How It Works

### App Startup Flow

1. App initializes Hive and registers adapters
2. `MigrationService` checks current schema version
3. If version < `CURRENT_SCHEMA_VERSION`:
   - Shows "Upgrading data..." loading screen
   - Creates backup of existing data
   - Runs migrations sequentially
   - Updates schema version on success
   - Shows error screen on failure
4. Initializes `TaskProvider` and loads main UI

### Migration Process

```dart
// Check if migration is needed
final needsMigration = await migrationService.needsMigration();

// Run migrations with progress callback
final result = await migrationService.runMigrations(
  onProgress: (status) => print(status),
);

if (result.success) {
  print('Migration completed: ${result.migrationsRun}');
} else {
  print('Migration failed: ${result.error}');
}
```

## Adding a New Migration

### Step 1: Update Schema Version

Update `lib/utils/app_utils.dart`:

```dart
class AppConstants {
  // Schema version for migrations
  static const int currentSchemaVersion = 2; // Increment this
  // ...
}
```

### Step 2: Create Migration Class

Create `lib/migrations/migration_X_to_Y.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/migration_service.dart';
import '../models/task.dart';
import '../models/category.dart' as models;

class Migration2To3 extends Migration {
  @override
  int get fromVersion => 2;

  @override
  int get toVersion => 3;

  @override
  String get description => 'Add tags field to tasks';

  @override
  Future<void> migrate(Box tasksBox, Box categoriesBox) async {
    try {
      debugPrint('Starting migration 2 -> 3');

      // Migrate tasks
      for (int i = 0; i < tasksBox.length; i++) {
        final task = tasksBox.getAt(i) as Task?;
        
        if (task == null) continue;

        // Example: Add default tags field
        // Note: You'll need to update the Task model first
        // final updatedTask = task.copyWith(tags: []);
        // await tasksBox.putAt(i, updatedTask);
      }

      debugPrint('Migration 2 -> 3 completed successfully');
    } catch (e) {
      debugPrint('Error in migration 2 -> 3: $e');
      rethrow;
    }
  }
}
```

### Step 3: Register Migration

Update `lib/services/migration_service.dart`:

```dart
void registerMigrations() {
  _registerMigration(Migration1To2());
  _registerMigration(Migration2To3()); // Add new migration
}
```

### Step 4: Update Model (if needed)

If adding new fields to Task or Category:

```dart
@HiveType(typeId: 1)
class Task extends HiveObject {
  // ... existing fields ...
  
  @HiveField(10) // Use next available field number
  List<String> tags;
  
  // Update constructor and copyWith
}
```

Don't forget to run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 5: Write Tests

Create tests in `test/migration_X_to_Y_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dooit/models/task.dart';
import 'package:dooit/migrations/migration_2_to_3.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hive.init('./test/hive_test_data');
    Hive.registerAdapter(TaskAdapter());
    // ... register other adapters
  });

  group('Migration2To3 Tests', () {
    test('should add tags field to existing tasks', () async {
      // Create test data with old schema
      // Run migration
      // Verify results
    });

    test('should handle null values', () async {
      // Test edge cases
    });

    test('should preserve existing data', () async {
      // Verify data integrity
    });
  });
}
```

## Migration Patterns

### Adding a Field

```dart
@override
Future<void> migrate(Box tasksBox, Box categoriesBox) async {
  for (int i = 0; i < tasksBox.length; i++) {
    final task = tasksBox.getAt(i) as Task?;
    if (task == null) continue;
    
    // Add new field with default value
    final updated = task.copyWith(newField: defaultValue);
    await tasksBox.putAt(i, updated);
  }
}
```

### Transforming Data

```dart
@override
Future<void> migrate(Box tasksBox, Box categoriesBox) async {
  for (int i = 0; i < tasksBox.length; i++) {
    final task = tasksBox.getAt(i) as Task?;
    if (task == null) continue;
    
    // Transform existing field
    final updated = task.copyWith(
      category: _transformCategory(task.category),
    );
    await tasksBox.putAt(i, updated);
  }
}

String _transformCategory(String oldCategory) {
  // Transform logic
  return newCategory;
}
```

### Handling Edge Cases

```dart
@override
Future<void> migrate(Box tasksBox, Box categoriesBox) async {
  int errorCount = 0;
  
  for (int i = 0; i < tasksBox.length; i++) {
    try {
      final task = tasksBox.getAt(i) as Task?;
      
      // Handle null
      if (task == null) {
        debugPrint('Null task at index $i');
        continue;
      }
      
      // Handle corrupted data
      if (!_isValidTask(task)) {
        debugPrint('Invalid task at index $i');
        errorCount++;
        continue;
      }
      
      // Perform migration
      // ...
    } catch (e) {
      debugPrint('Error at index $i: $e');
      errorCount++;
    }
  }
  
  if (errorCount > 0) {
    debugPrint('Migration completed with $errorCount errors');
  }
}

bool _isValidTask(Task task) {
  return task.title.isNotEmpty && task.id.isNotEmpty;
}
```

### Deleting a Field

```dart
// 1. Remove @HiveField annotation from model
// 2. Don't reference field in migration
// 3. Hive will ignore the old field automatically
// 4. Field will be removed from storage on next save

@override
Future<void> migrate(Box tasksBox, Box categoriesBox) async {
  // Just load and save each task to clean up old fields
  for (int i = 0; i < tasksBox.length; i++) {
    final task = tasksBox.getAt(i) as Task?;
    if (task != null) {
      await tasksBox.putAt(i, task); // Saves without old field
    }
  }
}
```

## Testing Migrations

### Unit Tests

```dart
test('should migrate tasks from v2 to v3', () async {
  // Setup: Create box with v2 data
  final tasksBox = await Hive.openBox<Task>('test_tasks');
  await tasksBox.add(createV2Task());
  
  // Execute: Run migration
  final migration = Migration2To3();
  await migration.migrate(tasksBox, categoriesBox);
  
  // Verify: Check results
  final migratedTask = tasksBox.getAt(0) as Task;
  expect(migratedTask.newField, equals(expectedValue));
  
  // Cleanup
  await tasksBox.close();
});
```

### Integration Tests

```dart
test('should run multiple sequential migrations', () async {
  // Start with v1 schema
  final versionBox = await Hive.openBox<AppVersion>('version');
  await versionBox.add(AppVersion(schemaVersion: 1, ...));
  
  // Run migrations
  final result = await migrationService.runMigrations();
  
  // Verify final state
  expect(result.success, isTrue);
  expect(result.migratedTo, equals(AppConstants.currentSchemaVersion));
  
  // Verify data integrity
  final tasksBox = await Hive.openBox<Task>('tasks');
  // Check all tasks migrated correctly
});
```

### Testing Rollback

```dart
test('should rollback on migration failure', () async {
  // Create backup-worthy data
  final tasksBox = await Hive.openBox<Task>('tasks');
  final originalTask = Task(title: 'Original');
  await tasksBox.add(originalTask);
  
  // Force migration failure
  // (e.g., by creating invalid migration)
  
  final result = await migrationService.runMigrations();
  
  // Verify rollback
  expect(result.success, isFalse);
  expect(result.backupPath, isNotNull);
  
  // Verify data restored
  final restoredTask = tasksBox.getAt(0) as Task;
  expect(restoredTask.title, equals('Original'));
});
```

## Best Practices

### 1. Always Test Migrations

- Write unit tests for each migration
- Test with real data from production
- Test edge cases (null values, empty boxes, corrupted data)
- Test rollback scenarios

### 2. Keep Migrations Small

- One migration per schema change
- Don't combine multiple changes
- Makes debugging easier
- Easier to roll back specific changes

### 3. Version Incrementally

- Increment schema version by 1 each time
- Don't skip versions
- Maintains clear migration path

### 4. Handle Errors Gracefully

- Catch and log errors for each item
- Don't fail entire migration for one bad item
- Track error counts
- Provide meaningful error messages

### 5. Validate Data

- Check for null values
- Validate data types
- Verify required fields
- Handle corrupted data

### 6. Document Changes

- Describe what each migration does
- Document any data transformations
- Note breaking changes
- Update this guide

### 7. Backup Strategy

- Backups are created automatically
- Keep last 5 backups by default
- Backups stored in app documents directory
- Manual restoration available if needed

### 8. Testing Strategy

- Test on fresh install (version 0)
- Test upgrading from each previous version
- Test with various data scenarios
- Test with production data backups

## Troubleshooting

### Migration Fails to Start

**Problem**: Migration service doesn't detect need for migration

**Solutions**:
- Check `currentSchemaVersion` in `AppConstants`
- Verify version box contains correct version
- Clear app data and reinstall

### Migration Fails During Execution

**Problem**: Error during migration, data may be corrupted

**Solutions**:
- Check logs for specific error
- Verify Hive adapters are registered
- Check for model definition issues
- Restore from automatic backup

### Backup Restoration

**Manual restoration**:
```dart
final backupService = BackupService();
final backups = await backupService.listBackups();
print('Available backups: $backups');

// Restore specific backup
await backupService.restoreBackup(
  backups.last,
  [AppConstants.tasksBoxName, AppConstants.categoriesBoxName],
);
```

### Data Loss After Migration

**Prevention**:
- Always test migrations thoroughly
- Verify backup creation before migration
- Test rollback functionality
- Keep multiple backup generations

**Recovery**:
- Check automatic backups in app documents directory
- Restore from most recent backup
- Report issue for investigation

## Version History

- **v1**: Initial schema (Task and Category models)
- **v2**: Example migration (planned, demonstrates pattern)

## Additional Resources

- [Hive Documentation](https://docs.hivedb.dev/)
- [Flutter State Management](https://flutter.dev/docs/development/data-and-backend/state-mgmt)
- [Testing Flutter Apps](https://flutter.dev/docs/testing)
