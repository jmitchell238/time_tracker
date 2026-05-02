import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/models/active_timer.dart';

void main() {
  final start = DateTime(2026, 4, 29, 8, 0, 0);

  group('ActiveTimer', () {
    test('toJson serializes all fields', () {
      final timer = ActiveTimer(
        id: 'abc',
        jobId: 'j1',
        rateOverride: 35.0,
        startedAt: start,
      );
      final json = timer.toJson();
      expect(json['id'], 'abc');
      expect(json['jobId'], 'j1');
      expect(json['rateOverride'], 35.0);
      expect(json['startedAt'], start.toIso8601String());
    });

    test('fromJson deserializes all fields', () {
      final json = {
        'id': 'abc',
        'jobId': 'j1',
        'rateOverride': 35.0,
        'startedAt': start.toIso8601String(),
      };
      final timer = ActiveTimer.fromJson(json);
      expect(timer.id, 'abc');
      expect(timer.jobId, 'j1');
      expect(timer.rateOverride, 35.0);
      expect(timer.startedAt, start);
    });

    test('round-trip toJson -> fromJson preserves all fields', () {
      final original = ActiveTimer(
        id: 'xyz',
        jobId: 'j2',
        rateOverride: 50.0,
        startedAt: start,
      );
      final copy = ActiveTimer.fromJson(original.toJson());
      expect(copy.id, original.id);
      expect(copy.jobId, original.jobId);
      expect(copy.rateOverride, original.rateOverride);
      expect(copy.startedAt, original.startedAt);
    });

    test('nullable fields serialize to null', () {
      final timer = ActiveTimer(id: 't1', startedAt: start);
      final json = timer.toJson();
      expect(json['jobId'], isNull);
      expect(json['rateOverride'], isNull);
    });

    test('fromJson handles null jobId and rateOverride', () {
      final json = {
        'id': 't1',
        'jobId': null,
        'rateOverride': null,
        'startedAt': start.toIso8601String(),
      };
      final timer = ActiveTimer.fromJson(json);
      expect(timer.jobId, isNull);
      expect(timer.rateOverride, isNull);
    });

    test('fromJson coerces int rateOverride to double', () {
      final json = {
        'id': 't1',
        'startedAt': start.toIso8601String(),
        'rateOverride': 40, // int, not double
      };
      final timer = ActiveTimer.fromJson(json);
      expect(timer.rateOverride, 40.0);
      expect(timer.rateOverride, isA<double>());
    });

    test('fromJson generates id when missing', () {
      final json = {
        'startedAt': start.toIso8601String(),
      };
      final timer = ActiveTimer.fromJson(json);
      expect(timer.id, isNotEmpty);
    });

    // Break/pause fields
    test('breakStartedAt defaults to null', () {
      final timer = ActiveTimer(id: 't1', startedAt: start);
      expect(timer.breakStartedAt, isNull);
    });

    test('totalBreakSeconds defaults to 0', () {
      final timer = ActiveTimer(id: 't1', startedAt: start);
      expect(timer.totalBreakSeconds, 0);
    });

    test('isOnBreak returns false when breakStartedAt is null', () {
      final timer = ActiveTimer(id: 't1', startedAt: start);
      expect(timer.isOnBreak, false);
    });

    test('isOnBreak returns true when breakStartedAt is set', () {
      final timer = ActiveTimer(
        id: 't1',
        startedAt: start,
        breakStartedAt: start.add(const Duration(hours: 1)),
      );
      expect(timer.isOnBreak, true);
    });

    test('toJson serializes breakStartedAt and totalBreakSeconds', () {
      final breakTime = start.add(const Duration(hours: 2));
      final timer = ActiveTimer(
        id: 't1',
        startedAt: start,
        breakStartedAt: breakTime,
        totalBreakSeconds: 600,
      );
      final json = timer.toJson();
      expect(json['breakStartedAt'], breakTime.toIso8601String());
      expect(json['totalBreakSeconds'], 600);
    });

    test('toJson serializes null breakStartedAt', () {
      final timer = ActiveTimer(id: 't1', startedAt: start);
      expect(timer.toJson()['breakStartedAt'], isNull);
    });

    test('fromJson deserializes breakStartedAt and totalBreakSeconds', () {
      final breakTime = start.add(const Duration(hours: 2));
      final json = {
        'id': 't1',
        'startedAt': start.toIso8601String(),
        'breakStartedAt': breakTime.toIso8601String(),
        'totalBreakSeconds': 600,
      };
      final timer = ActiveTimer.fromJson(json);
      expect(timer.breakStartedAt, breakTime);
      expect(timer.totalBreakSeconds, 600);
    });

    test('fromJson defaults totalBreakSeconds to 0 when missing', () {
      final json = {'id': 't1', 'startedAt': start.toIso8601String()};
      expect(ActiveTimer.fromJson(json).totalBreakSeconds, 0);
    });

    test('fromJson handles null breakStartedAt', () {
      final json = {
        'id': 't1',
        'startedAt': start.toIso8601String(),
        'breakStartedAt': null,
      };
      expect(ActiveTimer.fromJson(json).breakStartedAt, isNull);
    });

    test('round-trip preserves break fields', () {
      final breakTime = start.add(const Duration(minutes: 90));
      final original = ActiveTimer(
        id: 't1',
        startedAt: start,
        breakStartedAt: breakTime,
        totalBreakSeconds: 300,
      );
      final copy = ActiveTimer.fromJson(original.toJson());
      expect(copy.breakStartedAt, original.breakStartedAt);
      expect(copy.totalBreakSeconds, original.totalBreakSeconds);
    });

    test('copyWith updates breakStartedAt', () {
      final timer = ActiveTimer(id: 't1', startedAt: start);
      final breakTime = start.add(const Duration(hours: 1));
      final updated = timer.copyWith(breakStartedAt: breakTime);
      expect(updated.breakStartedAt, breakTime);
      expect(updated.startedAt, start);
    });

    test('copyWith updates totalBreakSeconds', () {
      final timer = ActiveTimer(id: 't1', startedAt: start);
      final updated = timer.copyWith(totalBreakSeconds: 120);
      expect(updated.totalBreakSeconds, 120);
    });

    test('copyWith can clear breakStartedAt with clearBreakStartedAt flag', () {
      final breakTime = start.add(const Duration(hours: 1));
      final timer = ActiveTimer(
          id: 't1', startedAt: start, breakStartedAt: breakTime);
      final cleared = timer.copyWith(clearBreakStartedAt: true);
      expect(cleared.breakStartedAt, isNull);
    });
  });
}
