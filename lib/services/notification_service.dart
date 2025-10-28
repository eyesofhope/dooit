import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task.dart';
import '../models/app_error.dart';
import '../services/logging_service.dart';
import '../utils/app_utils.dart';
import '../utils/error_messages.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final LoggingService _loggingService = LoggingService();
  bool _initialized = false;
  bool _permissionsGranted = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _loggingService.info('Initializing NotificationService', context: 'NotificationService');

      tz_data.initializeTimeZones();
      
      final String timeZoneName = await _getTimeZoneName();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (Platform.isAndroid) {
        await _createAndroidNotificationChannel();
        _permissionsGranted = await _requestAndroidPermissions();
      }

      if (Platform.isIOS) {
        _permissionsGranted = await _requestIOSPermissions();
      }

      _initialized = true;
      _loggingService.info(
        'NotificationService initialized successfully (permissions: $_permissionsGranted)',
        context: 'NotificationService',
      );
    } catch (e, stackTrace) {
      final error = NotificationError(
        message: ErrorMessages.notificationInitFailed,
        technicalDetails: e.toString(),
        stackTrace: stackTrace,
        context: 'NotificationService.initialize',
      );
      _loggingService.logAppError(error);
      _initialized = false;
      _permissionsGranted = false;
    }
  }

  Future<String> _getTimeZoneName() async {
    // Try to get system timezone, fallback to UTC
    try {
      return tz.local.name;
    } catch (e) {
      debugPrint('Could not get local timezone, using UTC: $e');
      return 'UTC';
    }
  }

  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
      debugPrint('Android notification channel created');
    }
  }

  Future<bool> _requestAndroidPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        final notificationsPermission = await androidImplementation.requestNotificationsPermission();
        final exactAlarmsPermission = await androidImplementation.requestExactAlarmsPermission();
        
        _loggingService.info(
          'Android permissions - Notifications: $notificationsPermission, Exact Alarms: $exactAlarmsPermission',
          context: 'NotificationService',
        );
        
        return notificationsPermission ?? false;
      }
      return false;
    } catch (e, stackTrace) {
      _loggingService.error(
        'Failed to request Android permissions',
        context: 'NotificationService._requestAndroidPermissions',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> _requestIOSPermissions() async {
    try {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosImplementation != null) {
        final result = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        
        _loggingService.info(
          'iOS permissions granted: $result',
          context: 'NotificationService',
        );
        
        return result ?? false;
      }
      return false;
    } catch (e, stackTrace) {
      _loggingService.error(
        'Failed to request iOS permissions',
        context: 'NotificationService._requestIOSPermissions',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> scheduleTaskNotification(Task task) async {
    if (!_initialized) await initialize();

    if (!_permissionsGranted) {
      throw PermissionError(
        message: ErrorMessages.permissionNotificationDenied,
        context: 'NotificationService.scheduleTaskNotification',
      );
    }

    if (task.dueDate == null || task.isCompleted) {
      _loggingService.debug(
        'Skipping notification: No due date or task completed',
        context: 'NotificationService',
      );
      return;
    }

    try {
      final scheduledDate = tz.TZDateTime.from(task.dueDate!, tz.local);
      final now = tz.TZDateTime.now(tz.local);

      if (scheduledDate.isBefore(now.add(const Duration(minutes: 1)))) {
        throw NotificationError(
          message: ErrorMessages.notificationPastDate,
          context: 'NotificationService.scheduleTaskNotification',
          severity: ErrorSeverity.warning,
        );
      }

      // Create notification details with enhanced configuration
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            channelDescription: AppConstants.notificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            enableLights: true,
            color: const Color(0xFF6750A4),
            autoCancel: true,
            ongoing: false,
            styleInformation: BigTextStyleInformation(
              task.description.isNotEmpty 
                  ? '${task.description}\n\nTap to view details' 
                  : 'Don\'t forget to complete this task!\n\nTap to view details',
              htmlFormatBigText: true,
              contentTitle: '📋 Task Reminder: ${task.title}',
              htmlFormatContentTitle: true,
              summaryText: 'DoIt - Task Manager',
              htmlFormatSummaryText: true,
            ),
            actions: <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'mark_done',
                'Mark Done',
                contextual: true,
              ),
              const AndroidNotificationAction(
                'see_more',
                'See More',
                contextual: false,
              ),
            ],
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        subtitle: 'Task Reminder',
        threadIdentifier: 'task_reminders',
        categoryIdentifier: 'task_reminder_category',
        interruptionLevel: InterruptionLevel.active,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      await cancelTaskNotification(task.id);

      await _notifications.zonedSchedule(
        task.id.hashCode,
        '📋 Task Reminder: ${task.title}',
        task.description.isNotEmpty
            ? '${task.description}\n\nTap to view details'
            : 'Don\'t forget to complete this task!\n\nTap to view details',
        scheduledDate,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      _loggingService.info(
        'Notification scheduled for task: "${task.title}" at $scheduledDate',
        context: 'NotificationService.scheduleTaskNotification',
      );
      
      final pendingNotifications = await getPendingNotifications();
      final scheduledNotification = pendingNotifications.firstWhere(
        (notification) => notification.id == task.id.hashCode,
        orElse: () => throw NotificationError(
          message: 'Notification verification failed',
          context: 'NotificationService.scheduleTaskNotification',
        ),
      );
      _loggingService.debug(
        'Verified scheduled notification: ${scheduledNotification.title}',
        context: 'NotificationService',
      );
      
    } catch (e, stackTrace) {
      final error = e is AppError
          ? e
          : NotificationError(
              message: ErrorMessages.notificationScheduleFailed,
              technicalDetails: e.toString(),
              stackTrace: stackTrace,
              context: 'NotificationService.scheduleTaskNotification - task: ${task.title}',
            );
      _loggingService.logAppError(error);
      throw error;
    }
  }

  Future<void> cancelTaskNotification(String taskId) async {
    if (!_initialized) await initialize();

    try {
      await _notifications.cancel(taskId.hashCode);
      _loggingService.debug('Notification cancelled for task: $taskId', context: 'NotificationService');
    } catch (e, stackTrace) {
      final error = NotificationError(
        message: ErrorMessages.notificationCancelFailed,
        technicalDetails: e.toString(),
        stackTrace: stackTrace,
        context: 'NotificationService.cancelTaskNotification',
        severity: ErrorSeverity.warning,
      );
      _loggingService.logAppError(error);
      throw error;
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();

    try {
      await _notifications.cancelAll();
      _loggingService.info('All notifications cancelled', context: 'NotificationService');
    } catch (e, stackTrace) {
      final error = NotificationError(
        message: ErrorMessages.notificationCancelFailed,
        technicalDetails: e.toString(),
        stackTrace: stackTrace,
        context: 'NotificationService.cancelAllNotifications',
      );
      _loggingService.logAppError(error);
      throw error;
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) await initialize();

    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e, stackTrace) {
      _loggingService.error(
        'Error getting pending notifications',
        context: 'NotificationService.getPendingNotifications',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final taskId = response.payload;
    if (taskId != null) {
      _loggingService.info('Notification tapped for task: $taskId', context: 'NotificationService');
    }
  }

  Future<void> showInstantNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          enableLights: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      _loggingService.debug('Instant notification shown: $title', context: 'NotificationService');
    } catch (e, stackTrace) {
      _loggingService.error(
        'Error showing instant notification',
        context: 'NotificationService.showInstantNotification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> scheduleTestNotification() async {
    if (!_initialized) await initialize();

    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
      
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            channelDescription: AppConstants.notificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            enableLights: true,
            color: Color(0xFF6750A4),
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notifications.zonedSchedule(
        999999,
        '🧪 Test Notification',
        'This is a test notification to verify the system is working!',
        scheduledDate,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      _loggingService.info('Test notification scheduled for: $scheduledDate', context: 'NotificationService');
    } catch (e, stackTrace) {
      _loggingService.error(
        'Error scheduling test notification',
        context: 'NotificationService.scheduleTestNotification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) await initialize();

    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidImplementation != null) {
          return await androidImplementation.areNotificationsEnabled() ?? false;
        }
      }

      return _permissionsGranted;
    } catch (e, stackTrace) {
      _loggingService.error(
        'Error checking notification permissions',
        context: 'NotificationService.areNotificationsEnabled',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  bool get hasPermissions => _permissionsGranted;
}
