# Testing Guide for DoIt Flutter App

This guide provides comprehensive information about the testing infrastructure and best practices for the DoIt application.

## Table of Contents
- [Test Structure](#test-structure)
- [Running Tests](#running-tests)
- [Writing Tests](#writing-tests)
- [Test Coverage](#test-coverage)
- [CI/CD Integration](#cicd-integration)

## Test Structure

```
test/
├── unit/                          # Unit tests for business logic
│   ├── app_utils_test.dart       # Utility functions tests
│   ├── task_provider_test.dart   # State management tests
│   └── notification_service_test.dart # Notification service tests
├── widget/                        # Widget tests for UI components
│   └── task_card_widget_test.dart
├── integration/                   # Integration tests for workflows
│   └── task_flow_integration_test.dart
├── golden/                        # Golden/screenshot tests
│   └── task_card_golden_test.dart
├── helpers/                       # Test utilities and mocks
│   ├── test_helpers.dart         # Test data factories
│   ├── mock_helpers.dart         # Mock object setup
│   └── test_config.dart          # Test configuration
└── flutter_test_config.dart      # Global test configuration
```

## Running Tests

### Basic Commands

**Run all tests:**
```bash
flutter test
```

**Run specific test directory:**
```bash
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
```

**Run specific test file:**
```bash
flutter test test/unit/app_utils_test.dart
```

**Run with verbose output:**
```bash
flutter test --verbose
```

**Run tests in random order:**
```bash
flutter test --test-randomize-ordering-seed=random
```

### Coverage Reports

**Generate coverage data:**
```bash
flutter test --coverage
```

**View coverage report (requires lcov):**
```bash
# Install lcov (Ubuntu/Debian)
sudo apt-get install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
start coverage/html/index.html  # Windows
```

### Golden Tests

**Update golden files:**
```bash
flutter test --update-goldens --tags=golden
```

**Run golden tests only:**
```bash
flutter test --tags=golden
```

## Writing Tests

### Unit Tests

Unit tests focus on testing individual functions and business logic in isolation.

**Example:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dooit/utils/app_utils.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('AppUtils Tests', () {
    test('formatDate returns correct format', () {
      final date = DateTime(2024, 1, 5);
      expect(AppUtils.formatDate(date), '05/01/2024');
    });

    test('sortTasks by priority works correctly', () {
      final tasks = TestData.createTasksWithPriorities();
      final sorted = AppUtils.sortTasks(tasks, SortOption.priority);
      
      expect(sorted.first.priority, TaskPriority.high);
      expect(sorted.last.priority, TaskPriority.low);
    });
  });
}
```

### Widget Tests

Widget tests verify UI behavior and user interactions.

**Example:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Task card displays title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TaskCard(task: testTask),
      ),
    );

    expect(find.text('Test Task'), findsOneWidget);
    
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    
    // Verify state change
  });
}
```

### Integration Tests

Integration tests verify complete workflows and feature interactions.

**Example:**
```dart
test('complete task workflow', () async {
  final provider = TaskProvider();
  
  // Add task
  await provider.addTask(testTask);
  expect(provider.totalTasks, 1);
  
  // Update task
  await provider.updateTask(updatedTask);
  expect(provider.getTaskById(testTask.id)?.title, 'Updated');
  
  // Complete task
  await provider.toggleTaskCompletion(testTask.id);
  expect(provider.completedTasks, 1);
  
  // Delete task
  await provider.deleteTask(testTask.id);
  expect(provider.totalTasks, 0);
});
```

### Golden Tests

Golden tests capture UI screenshots and verify visual consistency.

**Example:**
```dart
import 'package:golden_toolkit/golden_toolkit.dart';

testGoldens('Task card appearance', (tester) async {
  await tester.pumpWidgetBuilder(
    TaskCard(task: testTask),
  );
  
  await screenMatchesGolden(tester, 'task_card_default');
});
```

## Test Helpers

### Using TestData Factory

The `TestData` class provides convenient methods for creating test data:

```dart
// Create single task
final task = TestData.createTask(
  title: 'My Task',
  priority: TaskPriority.high,
  isCompleted: false,
);

// Create multiple tasks
final tasks = TestData.createTaskList(count: 10);

// Create tasks with specific properties
final priorityTasks = TestData.createTasksWithPriorities();
final completedTasks = TestData.createCompletedAndPendingTasks();
final categorizedTasks = TestData.createTasksWithCategories();
```

### Using Mock Helpers

Mock helpers simplify mocking of dependencies:

```dart
import '../helpers/mock_helpers.dart';

final mockBox = MockBox<Task>();
final tasks = <Task>[];
setupMockBox(mockBox, tasks);

// Now mockBox behaves like a real Hive box
```

## Test Coverage

### Coverage Requirements

- **Minimum overall coverage:** 80%
- **Critical components:** AppUtils, TaskProvider, NotificationService
- **Coverage targets:**
  - AppUtils: 90%+
  - TaskProvider: 85%+
  - NotificationService: 80%+

### Checking Coverage

```bash
# Run tests with coverage
flutter test --coverage

# Check coverage summary
lcov --summary coverage/lcov.info

# Check coverage for specific file
lcov --list coverage/lcov.info | grep app_utils.dart
```

### Improving Coverage

1. Identify uncovered lines:
   ```bash
   genhtml coverage/lcov.info -o coverage/html
   # Open coverage/html/index.html to see detailed report
   ```

2. Write tests for uncovered code paths
3. Focus on:
   - Edge cases
   - Error handling
   - Boundary conditions
   - Null safety

## Best Practices

### Test Organization

1. **Group related tests:**
   ```dart
   group('Date formatting', () {
     test('formats date correctly', () { ... });
     test('handles null dates', () { ... });
   });
   ```

2. **Use setUp and tearDown:**
   ```dart
   late TaskProvider provider;
   
   setUp(() {
     provider = TaskProvider();
   });
   
   tearDown(() {
     provider.dispose();
   });
   ```

3. **Use descriptive test names:**
   ```dart
   test('returns empty string when date is null', () { ... });
   ```

### Test Quality

1. **Test one thing at a time**
2. **Use meaningful assertions**
3. **Avoid test interdependence**
4. **Mock external dependencies**
5. **Test edge cases and error conditions**

### Common Patterns

**Testing async operations:**
```dart
test('async operation completes', () async {
  await provider.addTask(task);
  expect(provider.totalTasks, 1);
});
```

**Testing state changes:**
```dart
test('notifies listeners on change', () {
  var notified = false;
  provider.addListener(() => notified = true);
  
  provider.setSortOption(SortOption.priority);
  
  expect(notified, isTrue);
});
```

**Testing exceptions:**
```dart
test('throws error for invalid input', () {
  expect(() => validateTask(invalidTask), throwsException);
});
```

## CI/CD Integration

### GitHub Actions Workflow

Tests run automatically on:
- Push to main, develop branches
- Pull requests to main, develop

### Workflow Steps

1. **Code checkout**
2. **Flutter setup**
3. **Dependency installation**
4. **Code formatting check**
5. **Static analysis**
6. **Test execution**
7. **Coverage generation**
8. **Coverage validation** (min 80%)
9. **Artifact upload**

### Local Pre-commit Checks

Before committing, run:
```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Check coverage
flutter test --coverage
lcov --summary coverage/lcov.info
```

## Troubleshooting

### Common Issues

**Golden test failures:**
```bash
# Update golden files
flutter test --update-goldens --tags=golden
```

**Coverage not generated:**
```bash
# Ensure test runs complete successfully
flutter test --coverage
# Check that coverage/lcov.info exists
```

**Mock setup errors:**
```dart
// Register fallback values for mocktail
setUpAll(() {
  registerFallbackValue(TestData.createTask());
});
```

**Widget test timeout:**
```dart
testWidgets('test name', (tester) async {
  // ...
}, timeout: Timeout(Duration(seconds: 30)));
```

## Additional Resources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Golden Toolkit Documentation](https://pub.dev/packages/golden_toolkit)
- [Test Coverage Best Practices](https://flutter.dev/docs/testing/code-debugging)
