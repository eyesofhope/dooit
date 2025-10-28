import 'dart:async';
import '../models/app_error.dart';
import '../services/logging_service.dart';

class RecoveryUtils {
  static final LoggingService _loggingService = LoggingService();

  static Future<T?> retryOperation<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    double backoffMultiplier = 2.0,
    String? context,
  }) async {
    int retryCount = 0;
    Duration currentDelay = initialDelay;

    while (retryCount < maxRetries) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        retryCount++;
        
        if (retryCount >= maxRetries) {
          _loggingService.error(
            'Operation failed after $maxRetries retries',
            context: context ?? 'RecoveryUtils.retryOperation',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }

        _loggingService.warning(
          'Operation failed (attempt $retryCount/$maxRetries), retrying after ${currentDelay.inMilliseconds}ms',
          context: context ?? 'RecoveryUtils.retryOperation',
          error: e,
        );

        await Future.delayed(currentDelay);
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }

    return null;
  }

  static Future<bool> safeOperation({
    required Future<void> Function() operation,
    String? context,
    Function(AppError)? onError,
  }) async {
    try {
      await operation();
      return true;
    } catch (e, stackTrace) {
      final error = e is AppError
          ? e
          : AppError(
              type: ErrorType.unknown,
              message: e.toString(),
              technicalDetails: e.toString(),
              stackTrace: stackTrace,
              context: context,
            );

      _loggingService.logAppError(error);
      onError?.call(error);
      return false;
    }
  }

  static bool isTransientError(Object error) {
    if (error is AppError) {
      switch (error.type) {
        case ErrorType.network:
          return true;
        case ErrorType.database:
          return error.technicalDetails?.contains('locked') ?? false;
        case ErrorType.notification:
          return false;
        case ErrorType.validation:
          return false;
        case ErrorType.permission:
          return false;
        case ErrorType.unknown:
          return true;
      }
    }
    return true;
  }

  static Duration getRetryDelay(int attemptNumber) {
    final baseDelay = 500;
    final delay = baseDelay * (1 << (attemptNumber - 1));
    return Duration(milliseconds: delay.clamp(500, 10000));
  }
}
