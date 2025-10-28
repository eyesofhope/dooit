import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestConfig {
  static void setupTestEnvironment() {
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  static MaterialApp wrapWithMaterialApp(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  static Widget buildTestableWidget(Widget widget) {
    return MaterialApp(
      home: widget,
    );
  }

  static Future<void> pumpWidgetWithTheme(
    WidgetTester tester,
    Widget widget, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        home: Scaffold(
          body: widget,
        ),
      ),
    );
  }

  static const testTimeout = Duration(seconds: 30);

  static DateTime createTestDate({
    int year = 2024,
    int month = 1,
    int day = 1,
    int hour = 12,
    int minute = 0,
  }) {
    return DateTime(year, month, day, hour, minute);
  }

  static DateTime now() => DateTime.now();
  
  static DateTime yesterday() => DateTime.now().subtract(const Duration(days: 1));
  
  static DateTime tomorrow() => DateTime.now().add(const Duration(days: 1));
  
  static DateTime nextWeek() => DateTime.now().add(const Duration(days: 7));
}
