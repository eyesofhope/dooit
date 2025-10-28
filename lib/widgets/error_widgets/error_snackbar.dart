import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_error.dart';

class ErrorSnackbar {
  static void show(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    VoidCallback? onSettings,
  }) {
    HapticFeedback.mediumImpact();

    final colorScheme = Theme.of(context).colorScheme;
    final duration = _getDurationForSeverity(error.severity);

    final actions = <Widget>[];
    
    if (onRetry != null) {
      actions.add(
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            onRetry();
          },
          child: const Text('Retry'),
        ),
      );
    }

    if (onSettings != null && error.type == ErrorType.permission) {
      actions.add(
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            onSettings();
          },
          child: const Text('Settings'),
        ),
      );
    }

    if (actions.isEmpty) {
      actions.add(
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            onDismiss?.call();
          },
          child: const Text('Dismiss'),
        ),
      );
    }

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            _getIconForSeverity(error.severity),
            color: _getColorForSeverity(error.severity, colorScheme),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error.userFriendlyMessage,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (error.actionGuidance != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    error.actionGuidance!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onInverseSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      backgroundColor: _getBackgroundColorForSeverity(error.severity, colorScheme),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      action: actions.length == 1
          ? SnackBarAction(
              label: actions.first is TextButton
                  ? (actions.first as TextButton).child.toString().replaceAll(RegExp(r'[^a-zA-Z]'), '')
                  : 'Dismiss',
              onPressed: () {
                if (actions.first is TextButton) {
                  (actions.first as TextButton).onPressed?.call();
                }
              },
              textColor: _getColorForSeverity(error.severity, colorScheme),
            )
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void showSimple(
    BuildContext context,
    String message, {
    ErrorSeverity severity = ErrorSeverity.info,
    Duration? duration,
  }) {
    final error = AppError(
      type: ErrorType.unknown,
      message: message,
      severity: severity,
    );
    show(context, error);
  }

  static Duration _getDurationForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return const Duration(seconds: 2);
      case ErrorSeverity.warning:
        return const Duration(seconds: 4);
      case ErrorSeverity.error:
        return const Duration(seconds: 6);
      case ErrorSeverity.fatal:
        return const Duration(seconds: 10);
    }
  }

  static IconData _getIconForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info_outline;
      case ErrorSeverity.warning:
        return Icons.warning_amber_rounded;
      case ErrorSeverity.error:
        return Icons.error_outline;
      case ErrorSeverity.fatal:
        return Icons.dangerous_outlined;
    }
  }

  static Color _getColorForSeverity(ErrorSeverity severity, ColorScheme colorScheme) {
    switch (severity) {
      case ErrorSeverity.info:
        return colorScheme.primary;
      case ErrorSeverity.warning:
        return Colors.orange[700]!;
      case ErrorSeverity.error:
        return colorScheme.error;
      case ErrorSeverity.fatal:
        return Colors.red[900]!;
    }
  }

  static Color _getBackgroundColorForSeverity(ErrorSeverity severity, ColorScheme colorScheme) {
    switch (severity) {
      case ErrorSeverity.info:
        return colorScheme.inverseSurface;
      case ErrorSeverity.warning:
        return Colors.orange[100]!;
      case ErrorSeverity.error:
        return colorScheme.errorContainer;
      case ErrorSeverity.fatal:
        return Colors.red[100]!;
    }
  }
}
