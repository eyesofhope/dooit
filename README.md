# dooit

# DoIt - Flutter To-Do List App

A comprehensive Flutter to-do list application with modern features and Material Design 3.

## Features

### Core Features
- **Add/Delete Tasks**: Create and manage tasks using a Floating Action Button and intuitive dialogs
- **Real-time Search**: Search tasks in real-time through the AppBar search functionality
- **Task Details**: Tap any task to view detailed information and edit properties
- **Notifications**: Set reminders for tasks with due dates using local notifications
- **RTL/LTR Support**: Full support for right-to-left and left-to-right text direction

### Advanced Features
- **Categories/Tags**: Organize tasks with customizable categories and color-coded filter chips
- **Priority Levels**: Assign Low, Medium, or High priority with visual color indicators
- **Completion Statistics**: View progress and task completion stats in the AppBar
- **Smart Sorting**: Sort tasks by priority, due date, creation date, alphabetical order, or completion status
- **Filtering Options**: Filter tasks by All, Pending, Completed, or Overdue status
- **Task Management**: Mark tasks as complete, edit, duplicate, or delete with confirmation dialogs

### Technical Features
- **State Management**: Uses Provider for reactive state management
- **Local Storage**: Hive database for fast, offline data persistence
- **Notifications**: Flutter Local Notifications for task reminders
- **Material Design 3**: Modern UI with adaptive themes (Light/Dark mode)
- **Cross-platform**: Supports Android, iOS, Web, Windows, macOS, and Linux

## Project Structure

```
lib/
├── main.dart                    # App entry point with initialization
├── models/                      # Data models
│   ├── task.dart               # Task model with Hive annotations
│   ├── task.g.dart             # Generated Hive adapter
│   ├── category.dart           # Category model
│   └── category.g.dart         # Generated category adapter
├── providers/                   # State management
│   └── task_provider.dart      # Main task provider with CRUD operations
├── screens/                     # Application screens
│   ├── todo_screen.dart        # Main todo list screen
│   └── task_detail_screen.dart # Task details and editing screen
├── services/                    # External services
│   └── notification_service.dart # Local notification handling
├── utils/                       # Utilities and constants
│   ├── app_constants.dart      # App constants and configuration
│   ├── app_theme.dart          # Material Design 3 themes
│   └── app_utils.dart          # Helper functions and utilities
└── widgets/                     # Reusable UI components
    ├── add_edit_task_dialog.dart # Task creation/editing dialog
    ├── filter_chips.dart       # Category filter chips
    ├── search_bar_widget.dart  # Search functionality
    ├── sort_dropdown.dart      # Sorting options dropdown
    ├── stats_card.dart         # Progress statistics card
    └── task_card.dart          # Individual task card widget
```

## Getting Started

### Prerequisites
- Flutter SDK (3.9.0 or higher)
- Dart SDK
- Android Studio or VS Code with Flutter extensions

### Installation

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Generate Hive adapters**
   ```bash
   flutter packages pub run build_runner build
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Usage

### Adding Tasks
1. Tap the **+** button in the bottom-right corner
2. Fill in the task details:
   - **Title**: Required task name
   - **Description**: Optional detailed description
   - **Category**: Choose from predefined categories
   - **Priority**: Select Low, Medium, or High
   - **Due Date & Time**: Optional deadline
   - **Reminder**: Enable notifications for due dates

### Managing Tasks
- **Complete**: Tap the checkbox to mark tasks as done
- **View Details**: Tap on any task card to see full details
- **Edit**: Use the edit button in task details or the popup menu
- **Delete**: Use the delete option in the popup menu
- **Search**: Tap the search icon in the AppBar

### Filtering and Sorting
- **Categories**: Use the horizontal filter chips to filter by category
- **Status**: Use filter chips for All, Pending, Completed, or Overdue tasks
- **Sorting**: Use the sort dropdown to organize tasks by various criteria

## Testing

[![Test Suite](https://github.com/yourusername/dooit/workflows/Test%20Suite/badge.svg)](https://github.com/yourusername/dooit/actions)

This project has comprehensive test coverage including unit tests, widget tests, and golden tests.

### Test Structure

```
test/
├── unit/                          # Unit tests
│   ├── app_utils_test.dart       # Tests for utility functions
│   ├── task_provider_test.dart   # Tests for state management
│   └── notification_service_test.dart # Tests for notifications
├── widget/                        # Widget tests
├── integration/                   # Integration tests
├── golden/                        # Golden/screenshot tests
│   └── task_card_golden_test.dart
└── helpers/                       # Test utilities
    ├── test_helpers.dart         # Test data and factories
    └── mock_helpers.dart         # Mock objects

```

### Running Tests

**Run all tests:**
```bash
flutter test
```

**Run unit tests only:**
```bash
flutter test test/unit/
```

**Run with coverage:**
```bash
flutter test --coverage
```

**View coverage report:**
```bash
# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html
# Open in browser
open coverage/html/index.html
```

**Run golden tests:**
```bash
flutter test --update-goldens --tags=golden
```

**Run specific test file:**
```bash
flutter test test/unit/app_utils_test.dart
```

### Test Coverage

The project maintains minimum 80% test coverage for critical components:
- **AppUtils**: Date formatting, sorting, filtering, and utility functions
- **TaskProvider**: CRUD operations, state management, filtering, and statistics
- **NotificationService**: Notification scheduling, cancellation, and timezone handling

### Writing Tests

Use the test helpers for creating test data:

```dart
import '../helpers/test_helpers.dart';

test('example test', () {
  // Create test task
  final task = TestData.createTask(
    title: 'Test Task',
    priority: TaskPriority.high,
  );
  
  // Create multiple tasks
  final tasks = TestData.createTaskList(count: 10);
});
```

### Continuous Integration

Tests run automatically on every push and pull request via GitHub Actions. The CI pipeline:
- Runs all unit and widget tests
- Checks code formatting with `dart format`
- Performs static analysis with `flutter analyze`
- Generates and validates test coverage (minimum 80%)
- Uploads coverage reports to Codecov
- Runs golden tests to ensure UI consistency
