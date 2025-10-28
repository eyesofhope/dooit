# Migrations Directory

This directory contains data migration implementations for schema changes to Task and Category models.

## Overview

Each migration file handles upgrading data from one schema version to the next. Migrations are executed sequentially during app startup if the stored schema version is lower than `AppConstants.currentSchemaVersion`.

## Existing Migrations

### Migration 1 → 2 (`migration_1_to_2.dart`)
**Description**: Example migration demonstrating the pattern for adding fields and transforming data.

**Changes**: 
- Validates existing tasks and categories
- Demonstrates error handling for null and corrupted data
- Pattern for future migrations to follow

## Creating a New Migration

1. **Increment schema version** in `lib/utils/app_utils.dart`:
   ```dart
   static const int currentSchemaVersion = 3; // Increment
   ```

2. **Create migration file** (e.g., `migration_2_to_3.dart`):
   ```dart
   class Migration2To3 extends Migration {
     @override
     int get fromVersion => 2;
     
     @override
     int get toVersion => 3;
     
     @override
     String get description => 'Your migration description';
     
     @override
     Future<void> migrate(Box tasksBox, Box categoriesBox) async {
       // Migration logic here
     }
   }
   ```

3. **Register migration** in `lib/services/migration_service.dart`:
   ```dart
   void registerMigrations() {
     _registerMigration(Migration1To2());
     _registerMigration(Migration2To3()); // Add here
   }
   ```

4. **Write tests** in `test/migration_2_to_3_test.dart`

5. **Update documentation** in `MIGRATION_GUIDE.md`

## Best Practices

- ✅ Keep migrations small and focused
- ✅ Handle null values and edge cases
- ✅ Log progress and errors
- ✅ Don't skip version numbers
- ✅ Test with real production data
- ✅ Document breaking changes

## Testing Migrations

```dart
test('should migrate data correctly', () async {
  // Setup: Create test data with old schema
  final tasksBox = await Hive.openBox<Task>('test_tasks');
  await tasksBox.add(Task(title: 'Old Task'));
  
  // Execute: Run migration
  final migration = Migration2To3();
  await migration.migrate(tasksBox, categoriesBox);
  
  // Verify: Check results
  final task = tasksBox.getAt(0) as Task;
  expect(task.newField, equals(expectedValue));
});
```

## Migration Flow

1. App starts → Check schema version
2. If outdated → Show "Upgrading data..." screen
3. Create automatic backup
4. Run migrations sequentially (1→2→3...)
5. Update version after each successful migration
6. On error → Restore from backup
7. Complete → Initialize app normally

## Rollback

If a migration fails:
- Automatic backup restoration kicks in
- Error screen shows failure message
- User data preserved from last backup
- Manual restoration available via `BackupService`

## Need Help?

See the comprehensive guide: [MIGRATION_GUIDE.md](../../MIGRATION_GUIDE.md)
