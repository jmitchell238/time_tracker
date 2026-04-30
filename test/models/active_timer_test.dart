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
  });
}
