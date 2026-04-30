import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/models/job.dart';

void main() {
  final createdAt = DateTime(2026, 1, 15, 9, 0, 0);

  Job makeJob({
    String id = 'j1',
    String name = 'Lawn Care',
    String description = 'Weekly mowing',
    double? rate = 45.0,
    bool isArchived = false,
  }) =>
      Job(
        id: id,
        name: name,
        description: description,
        rate: rate,
        isArchived: isArchived,
        createdAt: createdAt,
      );

  group('Job', () {
    test('toJson serializes all fields', () {
      final j = makeJob().toJson();
      expect(j['id'], 'j1');
      expect(j['name'], 'Lawn Care');
      expect(j['description'], 'Weekly mowing');
      expect(j['rate'], 45.0);
      expect(j['isArchived'], false);
      expect(j['createdAt'], createdAt.toIso8601String());
    });

    test('toJson serializes null rate', () {
      final j = makeJob(rate: null).toJson();
      expect(j['rate'], isNull);
    });

    test('fromJson deserializes all fields', () {
      final job = Job.fromJson({
        'id': 'j1',
        'name': 'Lawn Care',
        'description': 'Weekly mowing',
        'rate': 45.0,
        'isArchived': false,
        'createdAt': createdAt.toIso8601String(),
      });
      expect(job.id, 'j1');
      expect(job.name, 'Lawn Care');
      expect(job.description, 'Weekly mowing');
      expect(job.rate, 45.0);
      expect(job.isArchived, false);
      expect(job.createdAt, createdAt);
    });

    test('fromJson coerces int rate to double', () {
      final job = Job.fromJson({
        'id': 'j1',
        'name': 'Test',
        'description': '',
        'rate': 40,
        'isArchived': false,
        'createdAt': createdAt.toIso8601String(),
      });
      expect(job.rate, 40.0);
      expect(job.rate, isA<double>());
    });

    test('fromJson handles null rate', () {
      final job = Job.fromJson({
        'id': 'j1',
        'name': 'Test',
        'rate': null,
        'isArchived': false,
        'createdAt': createdAt.toIso8601String(),
      });
      expect(job.rate, isNull);
    });

    test('fromJson defaults description to empty string when missing', () {
      final job = Job.fromJson({
        'id': 'j1',
        'name': 'Test',
        'isArchived': false,
        'createdAt': createdAt.toIso8601String(),
      });
      expect(job.description, '');
    });

    test('fromJson defaults isArchived to false when missing', () {
      final job = Job.fromJson({
        'id': 'j1',
        'name': 'Test',
        'createdAt': createdAt.toIso8601String(),
      });
      expect(job.isArchived, false);
    });

    test('round-trip toJson -> fromJson preserves all fields', () {
      final original = makeJob();
      final copy = Job.fromJson(original.toJson());
      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.description, original.description);
      expect(copy.rate, original.rate);
      expect(copy.isArchived, original.isArchived);
      expect(copy.createdAt, original.createdAt);
    });

    test('copyWith updates name', () {
      final updated = makeJob().copyWith(name: 'Snow Removal');
      expect(updated.name, 'Snow Removal');
    });

    test('copyWith updates rate', () {
      final updated = makeJob().copyWith(rate: 60.0);
      expect(updated.rate, 60.0);
    });

    test('copyWith with clearRate sets rate to null', () {
      final updated = makeJob(rate: 45.0).copyWith(clearRate: true);
      expect(updated.rate, isNull);
    });

    test('copyWith updates isArchived', () {
      final updated = makeJob(isArchived: false).copyWith(isArchived: true);
      expect(updated.isArchived, true);
    });

    test('copyWith preserves id and createdAt', () {
      final updated = makeJob().copyWith(name: 'Other');
      expect(updated.id, 'j1');
      expect(updated.createdAt, createdAt);
    });

    test('copyWith preserves unchanged fields', () {
      final updated = makeJob().copyWith(name: 'Other');
      expect(updated.description, 'Weekly mowing');
      expect(updated.rate, 45.0);
      expect(updated.isArchived, false);
    });
  });
}
