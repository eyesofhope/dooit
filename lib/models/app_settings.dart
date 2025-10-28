import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'task.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 4)
enum DefaultDueDate {
  @HiveField(0)
  none,
  @HiveField(1)
  today,
  @HiveField(2)
  tomorrow,
  @HiveField(3)
  nextWeek,
}

@HiveType(typeId: 5)
class AppSettings extends HiveObject {
  @HiveField(0)
  String themeMode;

  @HiveField(1)
  bool useDynamicColors;

  @HiveField(2)
  double textScale;

  @HiveField(3)
  bool notificationSound;

  @HiveField(4)
  bool notificationVibration;

  @HiveField(5)
  TaskPriority defaultPriority;

  @HiveField(6)
  String? defaultCategoryId;

  @HiveField(7)
  int defaultReminderHour;

  @HiveField(8)
  int defaultReminderMinute;

  @HiveField(9)
  DefaultDueDate defaultDueDate;

  @HiveField(10)
  bool autoCompleteSubtasks;

  @HiveField(11)
  bool remindIncompleteSubtasks;

  AppSettings({
    this.themeMode = 'system',
    this.useDynamicColors = true,
    this.textScale = 1.0,
    this.notificationSound = true,
    this.notificationVibration = true,
    this.defaultPriority = TaskPriority.medium,
    this.defaultCategoryId,
    this.defaultReminderHour = 9,
    this.defaultReminderMinute = 0,
    this.defaultDueDate = DefaultDueDate.none,
    this.autoCompleteSubtasks = false,
    this.remindIncompleteSubtasks = false,
  });

  ThemeMode get themeModeEnum {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  TimeOfDay get defaultReminderTime =>
      TimeOfDay(hour: defaultReminderHour, minute: defaultReminderMinute);

  void setDefaultReminderTime(TimeOfDay time) {
    defaultReminderHour = time.hour;
    defaultReminderMinute = time.minute;
  }

  AppSettings copyWith({
    String? themeMode,
    bool? useDynamicColors,
    double? textScale,
    bool? notificationSound,
    bool? notificationVibration,
    TaskPriority? defaultPriority,
    String? defaultCategoryId,
    int? defaultReminderHour,
    int? defaultReminderMinute,
    DefaultDueDate? defaultDueDate,
    bool? autoCompleteSubtasks,
    bool? remindIncompleteSubtasks,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      useDynamicColors: useDynamicColors ?? this.useDynamicColors,
      textScale: textScale ?? this.textScale,
      notificationSound: notificationSound ?? this.notificationSound,
      notificationVibration: notificationVibration ?? this.notificationVibration,
      defaultPriority: defaultPriority ?? this.defaultPriority,
      defaultCategoryId: defaultCategoryId ?? this.defaultCategoryId,
      defaultReminderHour: defaultReminderHour ?? this.defaultReminderHour,
      defaultReminderMinute: defaultReminderMinute ?? this.defaultReminderMinute,
      defaultDueDate: defaultDueDate ?? this.defaultDueDate,
      autoCompleteSubtasks: autoCompleteSubtasks ?? this.autoCompleteSubtasks,
      remindIncompleteSubtasks:
          remindIncompleteSubtasks ?? this.remindIncompleteSubtasks,
    );
  }

  static AppSettings getDefault() {
    return AppSettings();
  }
}
