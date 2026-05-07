import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/models/job.dart';
import 'package:time_tracker/models/time_entry.dart';
import 'package:time_tracker/utils/job_sort.dart';

Job _job(String id, String name, {DateTime? createdAt}) => Job(
      id: id,
      name: name,
      description: '',
      isArchived: false,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
    );

TimeEntry _entry(String jobId, String date) => TimeEntry(
      id: 'e-$jobId-$date',
      jobId: jobId,
      date: date,
      startTime: '09:00',
      endTime: '10:00',
      hours: 1.0,
      description: '',
    );

void main() {
  // ── sortJobsByRecent ──────────────────────────────────────────────────────

  group('sortJobsByRecent', () {
    test('job with more recent entry comes first', () {
      final jobs = [_job('a', 'Alpha'), _job('b', 'Beta')];
      final entries = [
        _entry('a', '2026-03-01'),
        _entry('b', '2026-04-01'),
      ];
      final result = sortJobsByRecent(jobs, entries);
      expect(result.map((j) => j.id).toList(), ['b', 'a']);
    });

    test('job with no entries comes after job with entries', () {
      final jobs = [_job('a', 'Alpha'), _job('b', 'Beta')];
      final entries = [_entry('b', '2026-01-01')];
      final result = sortJobsByRecent(jobs, entries);
      expect(result.map((j) => j.id).toList(), ['b', 'a']);
    });

    test('among no-entry jobs, newer createdAt comes first', () {
      final jobs = [
        _job('a', 'Alpha', createdAt: DateTime(2026, 1, 1)),
        _job('b', 'Beta', createdAt: DateTime(2026, 3, 1)),
      ];
      final result = sortJobsByRecent(jobs, []);
      expect(result.map((j) => j.id).toList(), ['b', 'a']);
    });

    test('job with multiple entries uses the most recent one', () {
      final jobs = [_job('a', 'Alpha'), _job('b', 'Beta')];
      final entries = [
        _entry('a', '2026-04-01'),
        _entry('a', '2026-01-01'),
        _entry('b', '2026-03-01'),
      ];
      final result = sortJobsByRecent(jobs, entries);
      expect(result.first.id, 'a');
    });

    test('returns empty list for empty input', () {
      expect(sortJobsByRecent([], []), isEmpty);
    });

    test('single job returns that job', () {
      final jobs = [_job('a', 'Alpha')];
      final result = sortJobsByRecent(jobs, []);
      expect(result.single.id, 'a');
    });
  });

  // ── groupJobsAlphabetically ───────────────────────────────────────────────

  group('groupJobsAlphabetically', () {
    test('groups jobs by first letter of name', () {
      final jobs = [_job('a', 'Alpha'), _job('b', 'Beta'), _job('c', 'Charlie')];
      final result = groupJobsAlphabetically(jobs);
      expect(result.map((g) => g.letter).toList(), ['A', 'B', 'C']);
    });

    test('multiple jobs in same letter group together', () {
      final jobs = [_job('a', 'Alpha'), _job('b', 'Aztec'), _job('c', 'Beta')];
      final result = groupJobsAlphabetically(jobs);
      expect(result.length, 2);
      expect(result[0].letter, 'A');
      expect(result[0].jobs.map((j) => j.id).toList(), containsAll(['a', 'b']));
    });

    test('jobs within a group are sorted by name', () {
      final jobs = [_job('a', 'Aztec'), _job('b', 'Alpha')];
      final result = groupJobsAlphabetically(jobs);
      expect(result.single.jobs.map((j) => j.name).toList(), ['Alpha', 'Aztec']);
    });

    test('groups are in alphabetical order', () {
      final jobs = [_job('a', 'Charlie'), _job('b', 'Alpha'), _job('c', 'Beta')];
      final result = groupJobsAlphabetically(jobs);
      expect(result.map((g) => g.letter).toList(), ['A', 'B', 'C']);
    });

    test('name starting with digit goes in # bucket', () {
      final jobs = [_job('a', '123 Job')];
      final result = groupJobsAlphabetically(jobs);
      expect(result.single.letter, '#');
    });

    test('returns empty list for empty input', () {
      expect(groupJobsAlphabetically([]), isEmpty);
    });

    test('case-insensitive grouping — lowercase name groups with uppercase', () {
      final jobs = [_job('a', 'apple'), _job('b', 'Avocado')];
      final result = groupJobsAlphabetically(jobs);
      expect(result.single.letter, 'A');
      expect(result.single.jobs.length, 2);
    });
  });
}
