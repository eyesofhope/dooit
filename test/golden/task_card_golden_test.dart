import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:dooit/models/task.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Golden Tests - Task Card', () {
    testGoldens('Task card with different priorities', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Low Priority Task',
          Container(
            width: 350,
            padding: const EdgeInsets.all(8),
            child: Card(
              child: ListTile(
                title: const Text('Low Priority Task'),
                subtitle: const Text('This is a low priority task'),
                trailing: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        )
        ..addScenario(
          'Medium Priority Task',
          Container(
            width: 350,
            padding: const EdgeInsets.all(8),
            child: Card(
              child: ListTile(
                title: const Text('Medium Priority Task'),
                subtitle: const Text('This is a medium priority task'),
                trailing: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        )
        ..addScenario(
          'High Priority Task',
          Container(
            width: 350,
            padding: const EdgeInsets.all(8),
            child: Card(
              child: ListTile(
                title: const Text('High Priority Task'),
                subtitle: const Text('This is a high priority task'),
                trailing: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        surfaceSize: const Size(400, 600),
      );

      await screenMatchesGolden(tester, 'task_card_priorities');
    });

    testGoldens('Task card states', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Pending Task',
          Container(
            width: 350,
            padding: const EdgeInsets.all(8),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.circle_outlined),
                title: const Text('Pending Task'),
                subtitle: const Text('Due in 2 days'),
              ),
            ),
          ),
        )
        ..addScenario(
          'Completed Task',
          Container(
            width: 350,
            padding: const EdgeInsets.all(8),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(
                  'Completed Task',
                  style: TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey[600],
                  ),
                ),
                subtitle: const Text('Completed today'),
              ),
            ),
          ),
        )
        ..addScenario(
          'Overdue Task',
          Container(
            width: 350,
            padding: const EdgeInsets.all(8),
            child: Card(
              color: Colors.red[50],
              child: const ListTile(
                leading: Icon(Icons.warning, color: Colors.red),
                title: Text('Overdue Task'),
                subtitle: Text('Due 2 days ago', style: TextStyle(color: Colors.red)),
              ),
            ),
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        surfaceSize: const Size(400, 600),
      );

      await screenMatchesGolden(tester, 'task_card_states');
    });

    testGoldens('Task card with text scale variations', (tester) async {
      final widget = Container(
        width: 350,
        padding: const EdgeInsets.all(8),
        child: Card(
          child: ListTile(
            title: const Text('Task with Long Title that Might Wrap'),
            subtitle: const Text('This is a description that contains quite a bit of text'),
            trailing: const Icon(Icons.arrow_forward_ios),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(400, 150),
      );

      await multiScreenGolden(
        tester,
        'task_card_text_scales',
        devices: [
          const Device(
            name: 'normal',
            size: Size(400, 150),
            textScale: 1.0,
          ),
          const Device(
            name: 'large_text',
            size: Size(400, 150),
            textScale: 1.5,
          ),
          const Device(
            name: 'extra_large_text',
            size: Size(400, 150),
            textScale: 2.0,
          ),
        ],
      );
    });
  });

  group('Golden Tests - Task List', () {
    testGoldens('Empty task list', (tester) async {
      final widget = Container(
        width: 350,
        height: 400,
        color: Colors.grey[100],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No tasks yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);
      await screenMatchesGolden(tester, 'empty_task_list');
    });

    testGoldens('Task list with multiple items', (tester) async {
      final widget = Container(
        width: 350,
        height: 400,
        child: ListView(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.circle_outlined),
                title: const Text('Task 1'),
                subtitle: const Text('General'),
                trailing: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(
                  'Task 2',
                  style: TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey[600],
                  ),
                ),
                subtitle: const Text('Work'),
              ),
            ),
            Card(
              color: Colors.red[50],
              child: const ListTile(
                leading: Icon(Icons.warning, color: Colors.red),
                title: Text('Task 3'),
                subtitle: Text('Overdue', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      );

      await tester.pumpWidgetBuilder(widget);
      await screenMatchesGolden(tester, 'task_list_multiple_items');
    });
  });
}
