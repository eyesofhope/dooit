import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/task.dart';
import 'models/category.dart' as models;
import 'models/app_error.dart';
import 'providers/task_provider.dart';
import 'services/notification_service.dart';
import 'services/logging_service.dart';
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

class DoItApp extends StatelessWidget {
  const DoItApp({super.key});

  @override
  Widget build(BuildContext context) {
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
              textDirection: TextDirection.ltr, // Support for RTL/LTR
              child: const TodoScreen(),
            ),
            builder: (context, child) {
              // Handle text scaling for accessibility
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
