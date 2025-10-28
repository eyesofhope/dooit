import 'package:hive/hive.dart';

part 'app_version.g.dart';

@HiveType(typeId: 3)
class AppVersion extends HiveObject {
  @HiveField(0)
  int schemaVersion;

  @HiveField(1)
  DateTime lastMigrationDate;

  @HiveField(2)
  String appVersion;

  AppVersion({
    required this.schemaVersion,
    required this.lastMigrationDate,
    required this.appVersion,
  });

  AppVersion copyWith({
    int? schemaVersion,
    DateTime? lastMigrationDate,
    String? appVersion,
  }) {
    return AppVersion(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      lastMigrationDate: lastMigrationDate ?? this.lastMigrationDate,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  @override
  String toString() {
    return 'AppVersion{schemaVersion: $schemaVersion, appVersion: $appVersion, lastMigrationDate: $lastMigrationDate}';
  }
}
