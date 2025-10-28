enum ErrorType {
  database,
  notification,
  validation,
  network,
  permission,
  unknown,
}

enum ErrorSeverity {
  info,
  warning,
  error,
  fatal,
}

class AppError implements Exception {
  final ErrorType type;
  final String message;
  final String? technicalDetails;
  final StackTrace? stackTrace;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final String? context;

  AppError({
    required this.type,
    required this.message,
    this.technicalDetails,
    this.stackTrace,
    this.severity = ErrorSeverity.error,
    DateTime? timestamp,
    this.context,
  }) : timestamp = timestamp ?? DateTime.now();

  String get userFriendlyMessage {
    switch (type) {
      case ErrorType.database:
        return 'We encountered a problem saving your data. Please try again.';
      case ErrorType.notification:
        return 'Unable to schedule notification. Check your notification permissions.';
      case ErrorType.validation:
        return message;
      case ErrorType.network:
        return 'Network connection error. Please check your internet connection.';
      case ErrorType.permission:
        return 'Permission required. Please enable in Settings.';
      case ErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  String? get actionGuidance {
    switch (type) {
      case ErrorType.database:
        return 'Check storage space and restart the app if the problem persists.';
      case ErrorType.notification:
        return 'Go to Settings > Notifications and enable permissions for DoIt.';
      case ErrorType.validation:
        return null;
      case ErrorType.network:
        return 'Check your internet connection and try again.';
      case ErrorType.permission:
        return 'Open device Settings and grant the necessary permissions.';
      case ErrorType.unknown:
        return 'Try restarting the app.';
    }
  }

  bool get isRecoverable {
    return severity != ErrorSeverity.fatal;
  }

  @override
  String toString() {
    return 'AppError{type: $type, message: $message, context: $context, severity: $severity, timestamp: $timestamp}';
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'message': message,
      'technicalDetails': technicalDetails,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'stackTrace': stackTrace?.toString(),
    };
  }
}

class DatabaseError extends AppError {
  DatabaseError({
    required String message,
    String? technicalDetails,
    StackTrace? stackTrace,
    String? context,
  }) : super(
          type: ErrorType.database,
          message: message,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
          severity: ErrorSeverity.error,
          context: context,
        );
}

class NotificationError extends AppError {
  NotificationError({
    required String message,
    String? technicalDetails,
    StackTrace? stackTrace,
    String? context,
    ErrorSeverity severity = ErrorSeverity.warning,
  }) : super(
          type: ErrorType.notification,
          message: message,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
          severity: severity,
          context: context,
        );
}

class ValidationError extends AppError {
  ValidationError({
    required String message,
    String? context,
  }) : super(
          type: ErrorType.validation,
          message: message,
          severity: ErrorSeverity.warning,
          context: context,
        );
}

class NetworkError extends AppError {
  NetworkError({
    required String message,
    String? technicalDetails,
    StackTrace? stackTrace,
    String? context,
  }) : super(
          type: ErrorType.network,
          message: message,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
          severity: ErrorSeverity.error,
          context: context,
        );
}

class PermissionError extends AppError {
  PermissionError({
    required String message,
    String? technicalDetails,
    StackTrace? stackTrace,
    String? context,
  }) : super(
          type: ErrorType.permission,
          message: message,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
          severity: ErrorSeverity.warning,
          context: context,
        );
}
