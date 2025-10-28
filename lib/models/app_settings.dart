import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 4)
enum BackupFrequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
}

@HiveType(typeId: 5)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool automaticBackupsEnabled;

  @HiveField(1)
  BackupFrequency backupFrequency;

  @HiveField(2)
  int backupsToKeep;

  @HiveField(3)
  bool includeCompletedTasks;

  @HiveField(4)
  bool backupOnAppClose;

  @HiveField(5)
  DateTime? lastBackupAt;

  AppSettings({
    this.automaticBackupsEnabled = true,
    this.backupFrequency = BackupFrequency.daily,
    this.backupsToKeep = 7,
    this.includeCompletedTasks = true,
    this.backupOnAppClose = false,
    this.lastBackupAt,
  });

  AppSettings copyWith({
    bool? automaticBackupsEnabled,
    BackupFrequency? backupFrequency,
    int? backupsToKeep,
    bool? includeCompletedTasks,
    bool? backupOnAppClose,
    DateTime? lastBackupAt,
  }) {
    return AppSettings(
      automaticBackupsEnabled:
          automaticBackupsEnabled ?? this.automaticBackupsEnabled,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      backupsToKeep: backupsToKeep ?? this.backupsToKeep,
      includeCompletedTasks: includeCompletedTasks ?? this.includeCompletedTasks,
      backupOnAppClose: backupOnAppClose ?? this.backupOnAppClose,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    );
  }

  static AppSettings defaults() => AppSettings();
}
