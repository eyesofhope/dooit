import 'package:hive/hive.dart';

part 'recurrence.g.dart';

@HiveType(typeId: 6)
enum RecurrenceType {
  @HiveField(0)
  none,
  @HiveField(1)
  daily,
  @HiveField(2)
  weekly,
  @HiveField(3)
  monthly,
  @HiveField(4)
  yearly,
}

@HiveType(typeId: 7)
class Recurrence {
  @HiveField(0)
  RecurrenceType type;

  @HiveField(1)
  int interval;

  @HiveField(2)
  DateTime? endDate;

  @HiveField(3)
  List<int>? weekdays;

  @HiveField(4)
  int? monthDay;

  @HiveField(5)
  bool useLastDayOfMonth;

  Recurrence({
    required this.type,
    this.interval = 1,
    this.endDate,
    this.weekdays,
    this.monthDay,
    this.useLastDayOfMonth = false,
  }) : interval = interval <= 0 ? 1 : interval;

  DateTime? getNextOccurrence(DateTime current) {
    if (type == RecurrenceType.none) {
      return null;
    }

    DateTime next;

    switch (type) {
      case RecurrenceType.none:
        return null;
      case RecurrenceType.daily:
        next = current.add(Duration(days: interval));
        break;
      case RecurrenceType.weekly:
        next = _nextWeekly(current);
        break;
      case RecurrenceType.monthly:
        next = _nextMonthly(current);
        break;
      case RecurrenceType.yearly:
        next = _nextYearly(current);
        break;
    }

    if (endDate != null && next.isAfter(endDate!)) {
      return null;
    }

    return next;
  }

  DateTime _nextWeekly(DateTime current) {
    final selectedWeekdays = (weekdays != null && weekdays!.isNotEmpty)
        ? weekdays!
        : <int>[current.weekday];

    final sortedWeekdays = List<int>.from(selectedWeekdays)..sort();

    for (final day in sortedWeekdays) {
      final delta = day - current.weekday;
      if (delta > 0) {
        return current.add(Duration(days: delta));
      }
    }

    final int daysUntilNextCycle =
        (7 - current.weekday) + sortedWeekdays.first + ((interval - 1) * 7);
    return current.add(Duration(days: daysUntilNextCycle));
  }

  DateTime _nextMonthly(DateTime current) {
    final targetDay = useLastDayOfMonth
        ? null
        : (monthDay != null && monthDay! >= 1 && monthDay! <= 31
            ? monthDay!
            : current.day);

    final DateTime tentative = DateTime(
      current.year,
      current.month + interval,
      1,
      current.hour,
      current.minute,
      current.second,
      current.millisecond,
      current.microsecond,
    );

    if (useLastDayOfMonth) {
      final lastDay = DateTime(tentative.year, tentative.month + 1, 0).day;
      return DateTime(
        tentative.year,
        tentative.month,
        lastDay,
        current.hour,
        current.minute,
        current.second,
        current.millisecond,
        current.microsecond,
      );
    }

    final lastDayOfTargetMonth =
        DateTime(tentative.year, tentative.month + 1, 0).day;
    final int desiredDay = ((targetDay ?? current.day)
            .clamp(1, lastDayOfTargetMonth))
        .toInt();

    return DateTime(
      tentative.year,
      tentative.month,
      desiredDay,
      current.hour,
      current.minute,
      current.second,
      current.millisecond,
      current.microsecond,
    );
  }

  DateTime _nextYearly(DateTime current) {
    final nextYearDate = DateTime(
      current.year + interval,
      current.month,
      current.day,
      current.hour,
      current.minute,
      current.second,
      current.millisecond,
      current.microsecond,
    );

    if (current.month == DateTime.february && current.day == 29) {
      final isLeapYear = _isLeapYear(nextYearDate.year);
      if (!isLeapYear) {
        return DateTime(
          nextYearDate.year,
          DateTime.february,
          28,
          nextYearDate.hour,
          nextYearDate.minute,
          nextYearDate.second,
          nextYearDate.millisecond,
          nextYearDate.microsecond,
        );
      }
    }

    return nextYearDate;
  }

  bool _isLeapYear(int year) {
    if (year % 400 == 0) return true;
    if (year % 100 == 0) return false;
    return year % 4 == 0;
  }
}
