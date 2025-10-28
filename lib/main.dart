import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'models/task.dart';
import 'models/category.dart' as models;
import 'models/app_version.dart';
import 'models/app_settings.dart';
import 'providers/task_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'services/migration_service.dart';
import 'screens/adaptive_todo_screen.dart';
import 'utils/app_theme.dart';
import 'utils/app_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(models.CategoryAdapter());
  Hive.registerAdapter(AppVersionAdapter());
  Hive.registerAdapter(DefaultDueDateAdapter());
  Hive.registerAdapter(AppSettingsAdapter());

  // Initialize notification service
  await NotificationService().initialize();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const DoItApp());
}

class DoItApp extends StatefulWidget {
  const DoItApp({super.key});

  @override
  State<DoItApp> createState() => _DoItAppState();
}

class _DoItAppState extends State<DoItApp> {
  bool _isMigrating = true;
  String _migrationStatus = 'Checking for updates...';
  MigrationResult? _migrationResult;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final migrationService = MigrationService();
      migrationService.registerMigrations();

      final currentVersion = await migrationService.getCurrentSchemaVersion();
      
      if (currentVersion == 0) {
        await migrationService.initializeVersion();
        setState(() {
          _isMigrating = false;
          _migrationStatus = 'Ready';
        });
        return;
      }

      final needsMigration = await migrationService.needsMigration();
      
      if (needsMigration) {
        setState(() {
          _migrationStatus = 'Upgrading data...';
        });

        final result = await migrationService.runMigrations(
          onProgress: (status) {
            setState(() {
              _migrationStatus = status;
            });
          },
        );

        setState(() {
          _migrationResult = result;
          _isMigrating = false;
          _migrationStatus = result.success ? 'Ready' : 'Migration failed';
        });

        if (!result.success) {
          debugPrint('Migration failed: ${result.error}');
        }
      } else {
        setState(() {
          _isMigrating = false;
          _migrationStatus = 'Ready';
        });
      }
    } catch (e) {
      debugPrint('Error during app initialization: $e');
      setState(() {
        _isMigrating = false;
        _migrationStatus = 'Initialization failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isMigrating) {
      return MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  _migrationStatus,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_migrationResult != null && !_migrationResult!.success) {
      return MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text(
                    'Migration Failed',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _migrationResult!.message,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => SettingsProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => TaskProvider()..initialize(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              ColorScheme lightColorScheme;
              ColorScheme darkColorScheme;

              if (settingsProvider.useDynamicColors && lightDynamic != null && darkDynamic != null) {
                lightColorScheme = lightDynamic.harmonized();
                darkColorScheme = darkDynamic.harmonized();
              } else {
                lightColorScheme = AppTheme.lightTheme.colorScheme;
                darkColorScheme = AppTheme.darkTheme.colorScheme;
              }

              return MaterialApp(
                title: AppConstants.appName,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme.copyWith(colorScheme: lightColorScheme),
                darkTheme: AppTheme.darkTheme.copyWith(colorScheme: darkColorScheme),
                themeMode: settingsProvider.themeMode,
                home: Directionality(
                  textDirection: TextDirection.ltr,
                  child: const AdaptiveTodoScreen(),
                ),
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(settingsProvider.textScale),
                    ),
                    child: child!,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
