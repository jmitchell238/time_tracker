import 'package:flutter_test/flutter_test.dart';

// Validates the week-start formula used in DashboardScreen._startOf('week'):
//   DateTime(year, month, day - weekday % 7)
//
// Dart's weekday: Monday=1 … Saturday=6, Sunday=7
// weekday % 7 gives days-since-Sunday: Mon=1, Tue=2, …, Sat=6, Sun=0
// Dart DateTime with day <= 0 wraps to the previous month (day 0 = last day of prev month).
void main() {
  group('week-start formula: DateTime(y, m, day - weekday%7)', () {
    test('Wednesday April 1 → Sunday March 29 (crosses month boundary)', () {
      // April 1, 2026 is a Wednesday (weekday=3): 1 - 3%7 = -2
      final result = DateTime(2026, 4, 1 - 3 % 7);
      expect(result, DateTime(2026, 3, 29));
      expect(result.weekday, 7); // Sunday
    });

    test('Tuesday January 1 → Sunday December 30 (crosses year boundary)', () {
      // January 1, 2019 is a Tuesday (weekday=2): 1 - 2%7 = -1
      final result = DateTime(2019, 1, 1 - 2 % 7);
      expect(result, DateTime(2018, 12, 30));
      expect(result.weekday, 7); // Sunday
    });

    test('Sunday: offset is 0, result is today', () {
      // weekday=7: 7%7=0, day - 0 = day → same day
      final result = DateTime(2026, 4, 5 - 7 % 7); // April 5, 2026 is Sunday
      expect(result, DateTime(2026, 4, 5));
      expect(result.weekday, 7); // Sunday
    });

    test('Monday: offset is 1, result is previous day (Sunday)', () {
      // weekday=1: 1%7=1, April 6 (Monday) → April 5 (Sunday)
      final result = DateTime(2026, 4, 6 - 1 % 7);
      expect(result, DateTime(2026, 4, 5));
      expect(result.weekday, 7); // Sunday
    });

    test('Saturday: offset is 6, result is 6 days before (Sunday)', () {
      // weekday=6: 6%7=6, April 11 (Saturday) → April 5 (Sunday)
      final result = DateTime(2026, 4, 11 - 6 % 7);
      expect(result, DateTime(2026, 4, 5));
      expect(result.weekday, 7); // Sunday
    });

    test('mid-month Wednesday: no month boundary, simple subtraction', () {
      // April 15, 2026 is a Wednesday (weekday=3): 15 - 3 = 12
      final result = DateTime(2026, 4, 15 - 3 % 7);
      expect(result, DateTime(2026, 4, 12));
      expect(result.weekday, 7); // Sunday
    });
  });
}
