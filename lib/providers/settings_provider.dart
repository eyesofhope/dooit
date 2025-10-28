import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import '../models/task.dart';
import '../utils/app_utils.dart';

class SettingsProvider extends ChangeNotifier {
  Box<AppSettings>? _settingsBox;
  AppSettings _settings = AppSettings.getDefault();

  AppSettings get settings => _settings;

  ThemeMode get themeMode => _settings.themeModeEnum;
  bool get useDynamicColors => _settings.useDynamicColors;
  double get textScale => _settings.textScale;
  bool get notificationSound => _settings.notificationSound;
  bool get notificationVibration => _settings.notificationVibration;
  TaskPriority get defaultPriority => _settings.defaultPriority;
  String? get defaultCategoryId => _settings.defaultCategoryId;
  TimeOfDay get defaultReminderTime => _settings.defaultReminderTime;
  DefaultDueDate get defaultDueDate => _settings.defaultDueDate;
  bool get autoCompleteSubtasks => _settings.autoCompleteSubtasks;
  bool get remindIncompleteSubtasks => _settings.remindIncompleteSubtasks;

  Future<void> initialize() async {
    try {
      _settingsBox = await Hive.openBox<AppSettings>(AppConstants.settingsBoxName);
      
      if (_settingsBox!.isEmpty) {
        final defaultSettings = AppSettings.getDefault();
        await _settingsBox!.add(defaultSettings);
        _settings = defaultSettings;
      } else {
        _settings = _settingsBox!.getAt(0) ?? AppSettings.getDefault();
      }

      notifyListeners();
      debugPrint('SettingsProvider initialized');
    } catch (e) {
      debugPrint('Error initializing SettingsProvider: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      if (_settingsBox != null && _settingsBox!.isNotEmpty) {
        await _settingsBox!.putAt(0, _settings);
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> setThemeMode(String mode) async {
    _settings.themeMode = mode;
    await _saveSettings();
    notifyListeners();
    debugPrint('Theme mode changed to: $mode');
  }

  Future<void> setUseDynamicColors(bool value) async {
    _settings.useDynamicColors = value;
    await _saveSettings();
    notifyListeners();
    debugPrint('Use dynamic colors changed to: $value');
  }

  Future<void> setTextScale(double scale) async {
    _settings.textScale = scale.clamp(0.8, 1.5);
    await _saveSettings();
    notifyListeners();
    debugPrint('Text scale changed to: $scale');
  }

  Future<void> setNotificationSound(bool value) async {
    _settings.notificationSound = value;
    await _saveSettings();
    notifyListeners();
    debugPrint('Notification sound changed to: $value');
  }

  Future<void> setNotificationVibration(bool value) async {
    _settings.notificationVibration = value;
    await _saveSettings();
    notifyListeners();
    debugPrint('Notification vibration changed to: $value');
  }

  Future<void> setAutoCompleteSubtasks(bool value) async {
    _settings.autoCompleteSubtasks = value;
    await _saveSettings();
    notifyListeners();
    debugPrint('Auto-complete subtasks changed to: $value');
  }

  Future<void> setRemindIncompleteSubtasks(bool value) async {
    _settings.remindIncompleteSubtasks = value;
    await _saveSettings();
    notifyListeners();
    debugPrint('Remind incomplete subtasks changed to: $value');
  }

  Future<void> setDefaultPriority(TaskPriority priority) async {
    _settings.defaultPriority = priority;
    await _saveSettings();
    notifyListeners();
    debugPrint('Default priority changed to: $priority');
  }

  Future<void> setDefaultCategory(String? categoryId) async {
    _settings.defaultCategoryId = categoryId;
    await _saveSettings();
    notifyListeners();
    debugPrint('Default category changed to: $categoryId');
  }

  Future<void> setDefaultReminderTime(TimeOfDay time) async {
    _settings.setDefaultReminderTime(time);
    await _saveSettings();
    notifyListeners();
    debugPrint('Default reminder time changed to: ${time.hour}:${time.minute}');
  }

  Future<void> setDefaultDueDate(DefaultDueDate dueDate) async {
    _settings.defaultDueDate = dueDate;
    await _saveSettings();
    notifyListeners();
    debugPrint('Default due date changed to: $dueDate');
  }

  Future<void> resetToDefaults() async {
    _settings = AppSettings.getDefault();
    await _saveSettings();
    notifyListeners();
    debugPrint('Settings reset to defaults');
  }

  @override
  void dispose() {
    _settingsBox?.close();
    super.dispose();
  }
}
