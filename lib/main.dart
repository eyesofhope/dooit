import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/task.dart';
import 'models/category.dart' as models;
import 'models/app_version.dart';
import 'providers/task_provider.dart';
import 'services/notification_service.dart';
import 'services/migration_service.dart';
import 'screens/todo_screen.dart';
import 'utils/app_theme.dart';
import 'utils/app_utils.dart';
import 'widgets/error_widgets/app_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final loggingService = LoggingService();
  await loggingService.initialize();

  FlutterError.onError = (FlutterErrorDetails details) {
    loggingService.error(
      'Flutter Error: ${details.exception}',
      context: 'FlutterError.onError',
      error: details.exception,
      stackTrace: details.stack,
    );
    
    FlutterError.presentError(details);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    loggingService.error(
      'Building Error Widget: ${details.exception}',
      context: 'ErrorWidget.builder',
      error: details.exception,
      stackTrace: details.stack,
    );

    return AppErrorWidget(
      errorDetails: details,
      onRetry: () {
        WidgetsBinding.instance.performReassemble();
      },
      onReportIssue: () {
        loggingService.info('User requested to report issue', context: 'ErrorWidget');
      },
    );
  };

  try {
    await Hive.initFlutter();
  // Register Hive adapters
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(models.CategoryAdapter());
  Hive.registerAdapter(AppVersionAdapter());

    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(TaskPriorityAdapter());
    Hive.registerAdapter(models.CategoryAdapter());

    await NotificationService().initialize();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    loggingService.info('Application initialized successfully');
  } catch (e, stackTrace) {
    loggingService.fatal(
      'Failed to initialize application',
      context: 'main',
      error: e,
      stackTrace: stackTrace,
    );
  }

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
          create: (context) => TaskProvider()..initialize(),
        ),
      ],
      child: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: Directionality(
              textDirection: TextDirection.ltr,
              child: const TodoScreen(),
            ),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.of(
                    context,
                  ).textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.5),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
