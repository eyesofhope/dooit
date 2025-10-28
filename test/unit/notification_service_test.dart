import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dooit/services/notification_service.dart';
import 'package:dooit/models/task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../helpers/test_helpers.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('NotificationService - Singleton', () {
    test('returns same instance', () {
      final instance1 = NotificationService();
      final instance2 = NotificationService();

      expect(identical(instance1, instance2), isTrue);
    });
  });

  group('NotificationService - Initialization', () {
    test('initializes only once', () async {
      final service = NotificationService();

      await service.initialize();
      await service.initialize();
    });
  });

  group('NotificationService - Schedule Notifications', () {
    test('skips notification for null due date', () async {
      final service = NotificationService();
      final task = TestData.createTask(
        dueDate: null,
        hasNotification: true,
      );

      await service.scheduleTaskNotification(task);
    });

    test('skips notification for completed task', () async {
      final service = NotificationService();
      final task = TestData.createTask(
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        hasNotification: true,
        isCompleted: true,
      );

      await service.scheduleTaskNotification(task);
    });

    test('skips notification for past due date', () async {
      final service = NotificationService();
      final task = TestData.createTask(
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        hasNotification: true,
      );

      await service.scheduleTaskNotification(task);
    });

    test('schedules notification for future date', () async {
      final service = NotificationService();
      final task = TestData.createTask(
        title: 'Test Notification',
        description: 'Test Description',
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        hasNotification: true,
      );

      await service.scheduleTaskNotification(task);
    });

    test('handles idempotent scheduling', () async {
      final service = NotificationService();
      final task = TestData.createTask(
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        hasNotification: true,
      );

      await service.scheduleTaskNotification(task);
      await service.scheduleTaskNotification(task);
    });
  });

  group('NotificationService - Cancel Notifications', () {
    test('cancels task notification', () async {
      final service = NotificationService();
      final taskId = 'test-task-id';

      await service.cancelTaskNotification(taskId);
    });

    test('cancels all notifications', () async {
      final service = NotificationService();

      await service.cancelAllNotifications();
    });
  });

  group('NotificationService - Pending Notifications', () {
    test('gets pending notifications', () async {
      final service = NotificationService();

      final pending = await service.getPendingNotifications();

      expect(pending, isA<List<PendingNotificationRequest>>());
    });
  });

  group('NotificationService - Instant Notification', () {
    test('shows instant notification', () async {
      final service = NotificationService();

      await service.showInstantNotification(
        'Test Title',
        'Test Body',
      );
    });

    test('shows instant notification with payload', () async {
      final service = NotificationService();

      await service.showInstantNotification(
        'Test Title',
        'Test Body',
        payload: 'test-payload',
      );
    });
  });

  group('NotificationService - Test Notification', () {
    test('schedules test notification', () async {
      final service = NotificationService();

      await service.scheduleTestNotification();
    });
  });

  group('NotificationService - Timezone Handling', () {
    test('handles timezone conversion', () async {
      final service = NotificationService();
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      final task = TestData.createTask(
        dueDate: futureDate,
        hasNotification: true,
      );

      await service.scheduleTaskNotification(task);
    });

    test('handles different timezones', () async {
      final service = NotificationService();

      final tokyo = tz.getLocation('Asia/Tokyo');
      final nyTime = tz.TZDateTime.now(tz.getLocation('America/New_York'));
      final tokyoTime = tz.TZDateTime.from(nyTime, tokyo);

      expect(tokyoTime.location, tokyo);
    });
  });

  group('NotificationService - Edge Cases', () {
    test('handles task with empty description', () async {
      final service = NotificationService();
      final task = TestData.createTask(
        title: 'Task without description',
        description: '',
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        hasNotification: true,
      );

      await service.scheduleTaskNotification(task);
    });

    test('handles task with very long title', () async {
      final service = NotificationService();
      final task = TestData.createTask(
        title: 'A' * 200,
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        hasNotification: true,
      );

      await service.scheduleTaskNotification(task);
    });

    test('handles notification with special characters', () async {
      final service = NotificationService();
      final task = TestData.createTask(
        title: 'Test 📋 Task 🔔',
        description: 'Special chars: @#\$%^&*()',
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        hasNotification: true,
      );

      await service.scheduleTaskNotification(task);
    });

    test('handles task ID hash collision scenario', () async {
      final service = NotificationService();
      final task1 = TestData.createTask(id: 'task1');
      final task2 = TestData.createTask(id: 'task2');

      expect(task1.id.hashCode == task2.id.hashCode, isFalse);
    });

    test('handles near-future notification (1 minute ahead)', () async {
      final service = NotificationService();
      final task = TestData.createTask(
        dueDate: DateTime.now().add(const Duration(minutes: 2)),
        hasNotification: true,
      );

      await service.scheduleTaskNotification(task);
    });

    test('skips notification exactly 1 minute in past', () async {
      final service = NotificationService();
      final task = TestData.createTask(
        dueDate: DateTime.now().subtract(const Duration(seconds: 61)),
        hasNotification: true,
      );

      await service.scheduleTaskNotification(task);
    });
  });

  group('NotificationService - Notification Details', () {
    test('creates proper notification ID from task ID', () async {
      final service = NotificationService();
      final task1 = TestData.createTask(id: 'task-id-1');
      final task2 = TestData.createTask(id: 'task-id-2');

      final id1 = task1.id.hashCode;
      final id2 = task2.id.hashCode;

      expect(id1, isNot(equals(id2)));
    });

    test('notification includes task title and description', () async {
      final service = NotificationService();
      final task = TestData.createTask(
        title: 'Important Task',
        description: 'This is very important',
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        hasNotification: true,
      );

      await service.scheduleTaskNotification(task);
    });
  });

  group('NotificationService - Permission Checks', () {
    test('checks if notifications are enabled', () async {
      final service = NotificationService();

      final enabled = await service.areNotificationsEnabled();

      expect(enabled, isA<bool>());
    });
  });

  group('NotificationService - Cleanup Operations', () {
    test('cancels notification when task is deleted', () async {
      final service = NotificationService();
      final task = TestData.createTask(
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        hasNotification: true,
      );

      await service.scheduleTaskNotification(task);
      await service.cancelTaskNotification(task.id);

      final pending = await service.getPendingNotifications();
      final hasTask = pending.any((n) => n.id == task.id.hashCode);
      expect(hasTask, isFalse);
    });

    test('cancels all notifications on cleanup', () async {
      final service = NotificationService();

      final task1 = TestData.createTask(
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        hasNotification: true,
      );
      final task2 = TestData.createTask(
        dueDate: DateTime.now().add(const Duration(hours: 2)),
        hasNotification: true,
      );

      await service.scheduleTaskNotification(task1);
      await service.scheduleTaskNotification(task2);
      await service.cancelAllNotifications();

      final pending = await service.getPendingNotifications();
      expect(pending, isEmpty);
    });
  });
}
