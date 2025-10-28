import 'package:flutter/material.dart';
import '../../models/app_error.dart';

class AppErrorWidget extends StatelessWidget {
  final FlutterErrorDetails? errorDetails;
  final VoidCallback? onRetry;
  final VoidCallback? onReportIssue;

  const AppErrorWidget({
    super.key,
    this.errorDetails,
    this.onRetry,
    this.onReportIssue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    String errorMessage = 'Something went wrong';
    String errorDetails = 'An unexpected error occurred. Please try again.';
    IconData errorIcon = Icons.error_outline;

    if (this.errorDetails?.exception is AppError) {
      final appError = this.errorDetails!.exception as AppError;
      errorMessage = appError.userFriendlyMessage;
      errorDetails = appError.actionGuidance ?? errorDetails;
      
      errorIcon = _getIconForErrorType(appError.type);
    }

    return Material(
      color: isDark ? Colors.grey[900] : Colors.grey[100],
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    errorIcon,
                    size: 64,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  errorMessage,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  errorDetails,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (onRetry != null)
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    if (onRetry != null && onReportIssue != null)
                      const SizedBox(width: 12),
                    if (onReportIssue != null)
                      OutlinedButton.icon(
                        onPressed: onReportIssue,
                        icon: const Icon(Icons.bug_report),
                        label: const Text('Report Issue'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForErrorType(ErrorType type) {
    switch (type) {
      case ErrorType.database:
        return Icons.storage_rounded;
      case ErrorType.notification:
        return Icons.notifications_off_rounded;
      case ErrorType.validation:
        return Icons.warning_rounded;
      case ErrorType.network:
        return Icons.wifi_off_rounded;
      case ErrorType.permission:
        return Icons.lock_rounded;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }
}
