// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dooit/main.dart';

void main() {
  testWidgets('Todo app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DoItApp());

    // Wait for app to initialize
    await tester.pumpAndSettle();

    // Verify that the app loads and shows the main screen
    expect(find.text('DoIt'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
