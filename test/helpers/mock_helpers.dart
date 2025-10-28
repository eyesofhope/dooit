import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox<T> extends Mock implements Box<T> {}

class MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockAndroidFlutterLocalNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class MockIOSFlutterLocalNotificationsPlugin extends Mock
    implements IOSFlutterLocalNotificationsPlugin {}

void setupMockBox<T>(MockBox<T> mockBox, List<T> items) {
  when(() => mockBox.values).thenReturn(items);
  when(() => mockBox.length).thenReturn(items.length);
  when(() => mockBox.isEmpty).thenReturn(items.isEmpty);
  when(() => mockBox.isNotEmpty).thenReturn(items.isNotEmpty);
  
  when(() => mockBox.add(any())).thenAnswer((invocation) async {
    items.add(invocation.positionalArguments[0] as T);
    return items.length - 1;
  });
  
  when(() => mockBox.putAt(any(), any())).thenAnswer((invocation) async {
    final index = invocation.positionalArguments[0] as int;
    final value = invocation.positionalArguments[1] as T;
    if (index >= 0 && index < items.length) {
      items[index] = value;
    }
  });
  
  when(() => mockBox.deleteAt(any())).thenAnswer((invocation) async {
    final index = invocation.positionalArguments[0] as int;
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  });
  
  when(() => mockBox.clear()).thenAnswer((_) async {
    items.clear();
    return 0;
  });
  
  when(() => mockBox.close()).thenAnswer((_) async {});
}
