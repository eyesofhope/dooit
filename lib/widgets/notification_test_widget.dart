import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationTestWidget extends StatelessWidget {
  const NotificationTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔔 Notification Test Center',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Test your notification system to ensure reminders work properly.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _testInstantNotification(context),
                    icon: const Icon(Icons.notifications),
                    label: const Text('Test Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _testScheduledNotification(context),
                    icon: const Icon(Icons.schedule),
                    label: const Text('Test 5s'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _testInstantNotification(BuildContext context) {
    NotificationService().showInstantNotification(
      '🧪 Instant Test Notification',
      'This notification appeared immediately! Your notification system is working. 🎉',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Instant notification sent! Check your notification bar.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _testScheduledNotification(BuildContext context) {
    NotificationService().scheduleTestNotification();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scheduled notification set for 5 seconds from now!'),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Got it',
          onPressed: null,
        ),
      ),
    );
  }
}