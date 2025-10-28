import '../models/app_error.dart';

class ErrorMessages {
  static const String databaseOpenFailed = 'Failed to open database';
  static const String databaseReadFailed = 'Failed to read data from database';
  static const String databaseWriteFailed = 'Failed to save data';
  static const String databaseDeleteFailed = 'Failed to delete data';
  
  static const String notificationScheduleFailed = 'Failed to schedule notification';
  static const String notificationCancelFailed = 'Failed to cancel notification';
  static const String notificationPermissionDenied = 'Notification permission denied';
  static const String notificationPastDate = 'Cannot schedule notification for past date';
  static const String notificationInitFailed = 'Failed to initialize notifications';
  
  static const String validationEmptyTitle = 'Task title cannot be empty';
  static const String validationInvalidDate = 'Invalid date selected';
  static const String validationEmptyCategory = 'Please select a category';
  static const String validationDuplicateTask = 'A task with this title already exists';
  
  static const String networkConnectionFailed = 'Connection failed';
  static const String networkTimeout = 'Request timed out';
  static const String networkUnreachable = 'Network unreachable';
  
  static const String permissionStorageDenied = 'Storage permission denied';
  static const String permissionNotificationDenied = 'Notification permission denied';
  
  static const String unknownError = 'An unexpected error occurred';
  static const String operationFailed = 'Operation failed';

  static String getErrorMessage(ErrorType type, {String? specificMessage}) {
    if (specificMessage != null) return specificMessage;
    
    switch (type) {
      case ErrorType.database:
        return databaseWriteFailed;
      case ErrorType.notification:
        return notificationScheduleFailed;
      case ErrorType.validation:
        return validationEmptyTitle;
      case ErrorType.network:
        return networkConnectionFailed;
      case ErrorType.permission:
        return permissionNotificationDenied;
      case ErrorType.unknown:
        return unknownError;
    }
  }

  static String getRecoveryGuidance(ErrorType type) {
    switch (type) {
      case ErrorType.database:
        return 'Try again or restart the app. Make sure you have enough storage space.';
      case ErrorType.notification:
        return 'Check notification permissions in your device settings.';
      case ErrorType.validation:
        return 'Please correct the input and try again.';
      case ErrorType.network:
        return 'Check your internet connection and try again.';
      case ErrorType.permission:
        return 'Grant the required permissions in your device settings.';
      case ErrorType.unknown:
        return 'Please try again. If the problem persists, restart the app.';
    }
  }
}
