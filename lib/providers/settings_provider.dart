import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import '../models/task.dart';
import '../models/category.dart' as models;
import '../services/backup_service.dart';
import '../utils/app_utils.dart';

class SettingsProvider extends ChangeNotifier {
  Box<AppSettings>? _settingsBox;
  AppSettings? _settings;

  AppSettings get settings => _settings ?? AppSettings.defaults();

  Future<void> initialize() async {
    try {
      _settingsBox = await Hive.openBox<AppSettings>(
        AppConstants.settingsBoxName,
      );

      if (_settingsBox!.isEmpty) {
        final defaultSettings = AppSettings.defaults();
        await _settingsBox!.add(defaultSettings);
        _settings = defaultSettings;
      } else {
        _settings = _settingsBox!.getAt(0);
      }

      debugPrint('SettingsProvider initialized');
    } catch (e) {
      debugPrint('Error initializing SettingsProvider: $e');
      _settings = AppSettings.defaults();
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    try {
      await _settingsBox?.putAt(0, newSettings);
      _settings = newSettings;
      notifyListeners();
      debugPrint('Settings updated');
    } catch (e) {
      debugPrint('Error updating settings: $e');
    }
  }

  Future<void> updateLastBackupDate(DateTime date) async {
    if (_settings != null) {
      final updated = _settings!.copyWith(lastBackupAt: date);
      await updateSettings(updated);
    }
  }

  Future<void> performAutomaticBackupIfNeeded({
    required List<Task> tasks,
    required List<models.Category> categories,
  }) async {
    try {
      final backupService = BackupService();
      final shouldBackup = await backupService.shouldCreateAutomaticBackup(settings);

      if (shouldBackup) {
        debugPrint('Creating automatic backup...');
        
        await backupService.createJsonBackup(
          tasks: tasks,
          categories: categories,
          type: BackupType.automatic,
          includeCompleted: settings.includeCompletedTasks,
        );

        await updateLastBackupDate(DateTime.now());
        
        await backupService.cleanOldJsonBackups(
          keepLast: settings.backupsToKeep,
          type: BackupType.automatic,
        );

        debugPrint('Automatic backup completed');
      }
    } catch (e) {
      debugPrint('Error performing automatic backup: $e');
    }
  }

  @override
  void dispose() {
    _settingsBox?.close();
    super.dispose();
  }
}
