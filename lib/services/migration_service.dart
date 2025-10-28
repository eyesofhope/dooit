import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_version.dart';
import '../utils/app_utils.dart';
import 'backup_service.dart';
import '../migrations/migration_1_to_2.dart';

abstract class Migration {
  int get fromVersion;
  int get toVersion;
  String get description;
  Future<void> migrate(Box tasksBox, Box categoriesBox);
}

class MigrationService {
  static final MigrationService _instance = MigrationService._internal();
  factory MigrationService() => _instance;
  MigrationService._internal();

  final BackupService _backupService = BackupService();
  final Map<int, Migration> _migrations = {};

  void registerMigrations() {
    _registerMigration(Migration1To2());
  }

  void _registerMigration(Migration migration) {
    _migrations[migration.fromVersion] = migration;
    debugPrint('Registered migration: ${migration.fromVersion} -> ${migration.toVersion}');
  }

  Future<int> getCurrentSchemaVersion() async {
    try {
      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      
      if (versionBox.isEmpty) {
        return 0;
      }
      
      final appVersion = versionBox.getAt(0);
      return appVersion?.schemaVersion ?? 0;
    } catch (e) {
      debugPrint('Error getting current schema version: $e');
      return 0;
    }
  }

  Future<void> initializeVersion() async {
    try {
      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      
      if (versionBox.isEmpty) {
        final appVersion = AppVersion(
          schemaVersion: AppConstants.currentSchemaVersion,
          lastMigrationDate: DateTime.now(),
          appVersion: AppConstants.appVersion,
        );
        await versionBox.add(appVersion);
        debugPrint('Initialized schema version: ${AppConstants.currentSchemaVersion}');
      }
    } catch (e) {
      debugPrint('Error initializing version: $e');
      rethrow;
    }
  }

  Future<void> updateSchemaVersion(int version) async {
    try {
      final versionBox = await Hive.openBox<AppVersion>(AppConstants.versionBoxName);
      
      final appVersion = AppVersion(
        schemaVersion: version,
        lastMigrationDate: DateTime.now(),
        appVersion: AppConstants.appVersion,
      );
      
      if (versionBox.isEmpty) {
        await versionBox.add(appVersion);
      } else {
        await versionBox.putAt(0, appVersion);
      }
      
      debugPrint('Updated schema version to: $version');
    } catch (e) {
      debugPrint('Error updating schema version: $e');
      rethrow;
    }
  }

  Future<bool> needsMigration() async {
    final currentVersion = await getCurrentSchemaVersion();
    return currentVersion < AppConstants.currentSchemaVersion;
  }

  Future<MigrationResult> runMigrations({
    Function(String)? onProgress,
  }) async {
    String? backupPath;
    
    try {
      final currentVersion = await getCurrentSchemaVersion();
      final targetVersion = AppConstants.currentSchemaVersion;

      if (currentVersion >= targetVersion) {
        debugPrint('No migration needed. Current version: $currentVersion');
        return MigrationResult(
          success: true,
          message: 'No migration needed',
          migratedFrom: currentVersion,
          migratedTo: currentVersion,
        );
      }

      onProgress?.call('Creating backup...');
      debugPrint('Creating backup before migration...');
      
      backupPath = await _backupService.createBackup([
        AppConstants.tasksBoxName,
        AppConstants.categoriesBoxName,
      ]);

      onProgress?.call('Running migrations...');
      debugPrint('Starting migration from version $currentVersion to $targetVersion');

      final tasksBox = await Hive.openBox(AppConstants.tasksBoxName);
      final categoriesBox = await Hive.openBox(AppConstants.categoriesBoxName);

      int version = currentVersion;
      final migrationsRun = <String>[];

      while (version < targetVersion) {
        final migration = _migrations[version];
        
        if (migration == null) {
          if (version == 0 && targetVersion == 1) {
            debugPrint('First installation - no migration needed');
            version = targetVersion;
            break;
          }
          
          throw MigrationException(
            'No migration found for version $version -> ${version + 1}',
          );
        }

        onProgress?.call('Migrating ${migration.description}...');
        debugPrint('Running migration: ${migration.description} (${migration.fromVersion} -> ${migration.toVersion})');
        
        await migration.migrate(tasksBox, categoriesBox);
        migrationsRun.add(migration.description);
        
        version = migration.toVersion;
        await updateSchemaVersion(version);
        
        debugPrint('Migration completed: ${migration.fromVersion} -> ${migration.toVersion}');
      }

      await _backupService.cleanOldBackups(keepLast: 5);

      onProgress?.call('Migration complete!');
      debugPrint('All migrations completed successfully');

      return MigrationResult(
        success: true,
        message: 'Migrations completed successfully',
        migratedFrom: currentVersion,
        migratedTo: targetVersion,
        migrationsRun: migrationsRun,
        backupPath: backupPath,
      );
    } catch (e, stackTrace) {
      debugPrint('Migration failed: $e');
      debugPrint('Stack trace: $stackTrace');

      if (backupPath != null) {
        try {
          onProgress?.call('Rolling back changes...');
          debugPrint('Attempting to restore from backup...');
          
          await _backupService.restoreBackup(backupPath, [
            AppConstants.tasksBoxName,
            AppConstants.categoriesBoxName,
          ]);
          
          debugPrint('Successfully restored from backup');
        } catch (restoreError) {
          debugPrint('Failed to restore backup: $restoreError');
        }
      }

      return MigrationResult(
        success: false,
        message: 'Migration failed: $e',
        migratedFrom: await getCurrentSchemaVersion(),
        migratedTo: await getCurrentSchemaVersion(),
        error: e.toString(),
        backupPath: backupPath,
      );
    }
  }
}

class MigrationResult {
  final bool success;
  final String message;
  final int migratedFrom;
  final int migratedTo;
  final List<String> migrationsRun;
  final String? error;
  final String? backupPath;

  MigrationResult({
    required this.success,
    required this.message,
    required this.migratedFrom,
    required this.migratedTo,
    this.migrationsRun = const [],
    this.error,
    this.backupPath,
  });

  @override
  String toString() {
    return 'MigrationResult{success: $success, message: $message, from: $migratedFrom, to: $migratedTo, migrations: $migrationsRun}';
  }
}

class MigrationException implements Exception {
  final String message;
  MigrationException(this.message);

  @override
  String toString() => 'MigrationException: $message';
}
