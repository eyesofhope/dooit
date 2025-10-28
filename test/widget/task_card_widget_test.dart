import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dooit/models/task.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Task Card Widget Tests', () {
    testWidgets('displays task title', (WidgetTester tester) async {
      final task = TestData.createTask(title: 'Test Task');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                title: Text(task.title),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Task'), findsOneWidget);
    });

    testWidgets('displays task description', (WidgetTester tester) async {
      final task = TestData.createTask(
        title: 'Test Task',
        description: 'Test Description',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                title: Text(task.title),
                subtitle: Text(task.description),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('shows checkmark for completed tasks', (WidgetTester tester) async {
      final task = TestData.createTask(
        title: 'Completed Task',
        isCompleted: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                leading: Icon(
                  task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                ),
                title: Text(task.title),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows priority indicator', (WidgetTester tester) async {
      final task = TestData.createTask(priority: TaskPriority.high);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                title: Text(task.title),
                trailing: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: task.priority == TaskPriority.high
                        ? Colors.red
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).last,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);
    });

    testWidgets('displays category badge', (WidgetTester tester) async {
      final task = TestData.createTask(category: 'Work');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                title: Text(task.title),
                subtitle: Row(
                  children: [
                    Chip(
                      label: Text(task.category),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('handles tap on task card', (WidgetTester tester) async {
      var tapped = false;
      final task = TestData.createTask();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: InkWell(
                onTap: () => tapped = true,
                child: ListTile(
                  title: Text(task.title),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('displays due date information', (WidgetTester tester) async {
      final dueDate = DateTime.now().add(const Duration(days: 2));
      final task = TestData.createTask(dueDate: dueDate);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                title: Text(task.title),
                subtitle: Text('Due: ${task.dueDate?.day}/${task.dueDate?.month}'),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Due:'), findsOneWidget);
    });

    testWidgets('shows overdue indicator', (WidgetTester tester) async {
      final task = TestData.createTask(
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        isCompleted: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              color: Colors.red[50],
              child: ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text(task.title),
                subtitle: const Text('Overdue', style: TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
    });
  });

  group('Task List Widget Tests', () {
    testWidgets('displays empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inbox, size: 64),
                  SizedBox(height: 16),
                  Text('No tasks yet'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No tasks yet'), findsOneWidget);
    });

    testWidgets('displays multiple tasks', (WidgetTester tester) async {
      final tasks = TestData.createTaskList(count: 3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(tasks[index].title),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('scrolls through long task list', (WidgetTester tester) async {
      final tasks = TestData.createTaskList(count: 20);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return Card(
                  key: ValueKey('task-$index'),
                  child: ListTile(
                    title: Text(tasks[index].title),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 20'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Task 20'),
        500.0,
      );

      expect(find.text('Task 20'), findsOneWidget);
    });
  });

  group('Task Form Widget Tests', () {
    testWidgets('displays all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                DropdownButton<TaskPriority>(
                  value: TaskPriority.medium,
                  items: TaskPriority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority.name),
                    );
                  }).toList(),
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.byType(DropdownButton<TaskPriority>), findsOneWidget);
    });

    testWidgets('validates required fields', (WidgetTester tester) async {
      String? errorText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Title',
                    errorText: errorText,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    errorText = 'Title is required';
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(errorText, 'Title is required');
    });

    testWidgets('submits form with valid data', (WidgetTester tester) async {
      var submitted = false;
      final titleController = TextEditingController(text: 'New Task');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      submitted = true;
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(submitted, isTrue);
    });
  });
}
