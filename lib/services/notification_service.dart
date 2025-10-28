import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task.dart';
import '../utils/app_utils.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone data
      tz_data.initializeTimeZones();
      
      // Set local timezone
      final String timeZoneName = await _getTimeZoneName();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      // Android initialization with notification channel
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      // Combined initialization settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      // Initialize the plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      if (Platform.isAndroid) {
        await _createAndroidNotificationChannel();
        await _requestAndroidPermissions();
      }

      // Request permissions for iOS
      if (Platform.isIOS) {
        await _requestIOSPermissions();
      }

      _initialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
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

  Future<void> _requestAndroidPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> _requestIOSPermissions() async {
    final IOSFlutterLocalNotificationsPlugin? iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> scheduleTaskNotification(Task task) async {
    if (!_initialized) await initialize();

    if (task.dueDate == null || task.isCompleted) {
      debugPrint('Skipping notification: No due date or task completed');
      return;
    }

    try {
      // Convert to TZDateTime
      final scheduledDate = tz.TZDateTime.from(task.dueDate!, tz.local);
      final now = tz.TZDateTime.now(tz.local);

      // Don't schedule notifications for past dates (with 1 minute buffer)
      if (scheduledDate.isBefore(now.add(const Duration(minutes: 1)))) {
        debugPrint('Skipping notification: Scheduled time is in the past');
        return;
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

      // Cancel existing notification for this task
      await cancelTaskNotification(task.id);

      // Schedule the new notification
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

      debugPrint(
        '✅ Notification scheduled successfully for task: "${task.title}" at $scheduledDate (Local: ${scheduledDate.toLocal()})',
      );
      
      // Verify the notification was scheduled
      final pendingNotifications = await getPendingNotifications();
      final scheduledNotification = pendingNotifications.firstWhere(
        (notification) => notification.id == task.id.hashCode,
        orElse: () => throw Exception('Notification not found'),
      );
      debugPrint('📅 Verified scheduled notification: ${scheduledNotification.title}');
      
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
      // Show a fallback instant notification for testing
      await showInstantNotification(
        'Notification Error',
        'Could not schedule reminder for "${task.title}". Error: $e',
        payload: task.id,
      );
    }
  }

  Future<void> cancelTaskNotification(String taskId) async {
    if (!_initialized) await initialize();

    try {
      await _notifications.cancel(taskId.hashCode);
      debugPrint('Notification cancelled for task: $taskId');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();

    try {
      await _notifications.cancelAll();
      debugPrint('All notifications cancelled');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) await initialize();

    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final taskId = response.payload;
    if (taskId != null) {
      debugPrint('Notification tapped for task: $taskId');
      // Here you can navigate to the task detail screen or perform other actions
      // This would typically be handled by a navigation service or callback
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
      debugPrint('✅ Instant notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing instant notification: $e');
    }
  }

  // Test notification method - shows a notification 5 seconds from now
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
        999999, // Test notification ID
        '🧪 Test Notification',
        'This is a test notification to verify the system is working!',
        scheduledDate,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('🧪 Test notification scheduled for: $scheduledDate');
    } catch (e) {
      debugPrint('❌ Error scheduling test notification: $e');
    }
  }

  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) await initialize();

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

    return true; // Assume enabled for iOS as permission is requested during initialization
  }
}
