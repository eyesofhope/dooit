import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_error.dart';

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  late Logger _logger;
  bool _initialized = false;
  String? _logFilePath;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kReleaseMode) {
        final directory = await getApplicationDocumentsDirectory();
        final logDir = Directory('${directory.path}/logs');
        
        if (!await logDir.exists()) {
          await logDir.create(recursive: true);
        }

        _logFilePath = '${logDir.path}/app_${DateTime.now().toIso8601String().split('T')[0]}.log';
        
        _logger = Logger(
          filter: ProductionFilter(),
          printer: PrettyPrinter(
            methodCount: 2,
            errorMethodCount: 8,
            lineLength: 120,
            colors: false,
            printEmojis: false,
            printTime: true,
          ),
          output: FileOutput(file: File(_logFilePath!)),
        );

        await _rotateLogFiles(logDir);
      } else {
        _logger = Logger(
          filter: DevelopmentFilter(),
          printer: PrettyPrinter(
            methodCount: 2,
            errorMethodCount: 8,
            lineLength: 120,
            colors: true,
            printEmojis: true,
            printTime: true,
          ),
          output: ConsoleOutput(),
        );
      }

      _initialized = true;
      debug('LoggingService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize LoggingService: $e');
      _logger = Logger(
        printer: SimplePrinter(),
        output: ConsoleOutput(),
      );
      _initialized = true;
    }
  }

  Future<void> _rotateLogFiles(Directory logDir) async {
    try {
      final files = logDir.listSync();
      final logFiles = files
          .whereType<File>()
          .where((file) => file.path.endsWith('.log'))
          .toList();

      logFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      if (logFiles.length > 7) {
        for (var i = 7; i < logFiles.length; i++) {
          await logFiles[i].delete();
          debug('Deleted old log file: ${logFiles[i].path}');
        }
      }
    } catch (e) {
      debugPrint('Error rotating log files: $e');
    }
  }

  void debug(String message, {String? context}) {
    if (!_initialized) return;
    _logger.d(_formatMessage(message, context));
  }

  void info(String message, {String? context}) {
    if (!_initialized) return;
    _logger.i(_formatMessage(message, context));
  }

  void warning(String message, {String? context, Object? error}) {
    if (!_initialized) return;
    if (error != null) {
      _logger.w(_formatMessage(message, context), error: error);
    } else {
      _logger.w(_formatMessage(message, context));
    }
  }

  void error(String message, {String? context, Object? error, StackTrace? stackTrace}) {
    if (!_initialized) return;
    _logger.e(
      _formatMessage(message, context),
      error: error,
      stackTrace: stackTrace,
    );
  }

  void fatal(String message, {String? context, Object? error, StackTrace? stackTrace}) {
    if (!_initialized) return;
    _logger.f(
      _formatMessage(message, context),
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logAppError(AppError appError) {
    if (!_initialized) return;

    final message = '''
Error Type: ${appError.type}
Severity: ${appError.severity}
Message: ${appError.message}
Context: ${appError.context ?? 'N/A'}
Technical Details: ${appError.technicalDetails ?? 'N/A'}
Timestamp: ${appError.timestamp}
''';

    switch (appError.severity) {
      case ErrorSeverity.info:
        info(message);
        break;
      case ErrorSeverity.warning:
        warning(message, error: appError.technicalDetails);
        break;
      case ErrorSeverity.error:
        error(
          message,
          error: appError.technicalDetails,
          stackTrace: appError.stackTrace,
        );
        break;
      case ErrorSeverity.fatal:
        fatal(
          message,
          error: appError.technicalDetails,
          stackTrace: appError.stackTrace,
        );
        break;
    }
  }

  String _formatMessage(String message, String? context) {
    if (context != null) {
      return '[$context] $message';
    }
    return message;
  }

  String? get logFilePath => _logFilePath;

  Future<List<File>> getLogFiles() async {
    try {
      if (kReleaseMode) {
        final directory = await getApplicationDocumentsDirectory();
        final logDir = Directory('${directory.path}/logs');
        
        if (!await logDir.exists()) {
          return [];
        }

        final files = logDir.listSync();
        final logFiles = files
            .whereType<File>()
            .where((file) => file.path.endsWith('.log'))
            .toList();

        logFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        
        return logFiles;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting log files: $e');
      return [];
    }
  }

  Future<void> clearOldLogs() async {
    try {
      if (kReleaseMode) {
        final directory = await getApplicationDocumentsDirectory();
        final logDir = Directory('${directory.path}/logs');
        
        if (await logDir.exists()) {
          await _rotateLogFiles(logDir);
          info('Old logs cleared');
        }
      }
    } catch (e) {
      debugPrint('Error clearing old logs: $e');
    }
  }
}

class FileOutput extends LogOutput {
  final File file;

  FileOutput({required this.file});

  @override
  void output(OutputEvent event) {
    try {
      final buffer = StringBuffer();
      for (var line in event.lines) {
        buffer.writeln(line);
      }
      file.writeAsStringSync(
        buffer.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      debugPrint('Error writing to log file: $e');
    }
  }
}
