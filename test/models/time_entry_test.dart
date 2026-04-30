import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/models/time_entry.dart';

void main() {
  TimeEntry makeEntry({
    String id = 'e1',
    String? jobId = 'j1',
    String date = '2026-04-01',
    String startTime = '09:00',
    String endTime = '17:00',
    double hours = 8.0,
    String description = 'Fixed bug',
    String? invoiceId = 'inv1',
    double? rateOverride = 45.0,
  }) =>
      TimeEntry(
        id: id,
        jobId: jobId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        hours: hours,
        description: description,
        invoiceId: invoiceId,
        rateOverride: rateOverride,
      );

  group('TimeEntry', () {
    test('toJson serializes all fields', () {
      final j = makeEntry().toJson();
      expect(j['id'], 'e1');
      expect(j['jobId'], 'j1');
      expect(j['date'], '2026-04-01');
      expect(j['startTime'], '09:00');
      expect(j['endTime'], '17:00');
      expect(j['hours'], 8.0);
      expect(j['description'], 'Fixed bug');
      expect(j['invoiceId'], 'inv1');
      expect(j['rateOverride'], 45.0);
    });

    test('toJson serializes null optional fields', () {
      final j = makeEntry(jobId: null, invoiceId: null, rateOverride: null).toJson();
      expect(j['jobId'], isNull);
      expect(j['invoiceId'], isNull);
      expect(j['rateOverride'], isNull);
    });

    test('fromJson deserializes all fields', () {
      final e = TimeEntry.fromJson({
        'id': 'e1',
        'jobId': 'j1',
        'date': '2026-04-01',
        'startTime': '09:00',
        'endTime': '17:00',
        'hours': 8.0,
        'description': 'Fixed bug',
        'invoiceId': 'inv1',
        'rateOverride': 45.0,
      });
      expect(e.id, 'e1');
      expect(e.jobId, 'j1');
      expect(e.date, '2026-04-01');
      expect(e.startTime, '09:00');
      expect(e.endTime, '17:00');
      expect(e.hours, 8.0);
      expect(e.description, 'Fixed bug');
      expect(e.invoiceId, 'inv1');
      expect(e.rateOverride, 45.0);
    });

    test('fromJson coerces int hours to double', () {
      final e = TimeEntry.fromJson({
        'id': 'e1',
        'date': '2026-04-01',
        'hours': 8,
        'description': '',
      });
      expect(e.hours, 8.0);
      expect(e.hours, isA<double>());
    });

    test('fromJson coerces int rateOverride to double', () {
      final e = TimeEntry.fromJson({
        'id': 'e1',
        'date': '2026-04-01',
        'hours': 0.0,
        'description': '',
        'rateOverride': 50,
      });
      expect(e.rateOverride, 50.0);
      expect(e.rateOverride, isA<double>());
    });

    test('fromJson defaults startTime to 00:00 when missing', () {
      final e = TimeEntry.fromJson({
        'id': 'e1',
        'date': '2026-04-01',
        'hours': 0.0,
        'description': '',
      });
      expect(e.startTime, '00:00');
    });

    test('fromJson defaults endTime to 00:00 when missing', () {
      final e = TimeEntry.fromJson({
        'id': 'e1',
        'date': '2026-04-01',
        'hours': 0.0,
        'description': '',
      });
      expect(e.endTime, '00:00');
    });

    test('fromJson defaults description to empty string when missing', () {
      final e = TimeEntry.fromJson({
        'id': 'e1',
        'date': '2026-04-01',
        'hours': 0.0,
      });
      expect(e.description, '');
    });

    test('fromJson handles null optional fields', () {
      final e = TimeEntry.fromJson({
        'id': 'e1',
        'date': '2026-04-01',
        'hours': 0.0,
        'description': '',
        'jobId': null,
        'invoiceId': null,
        'rateOverride': null,
      });
      expect(e.jobId, isNull);
      expect(e.invoiceId, isNull);
      expect(e.rateOverride, isNull);
    });

    test('round-trip toJson -> fromJson preserves all fields', () {
      final original = makeEntry();
      final copy = TimeEntry.fromJson(original.toJson());
      expect(copy.id, original.id);
      expect(copy.jobId, original.jobId);
      expect(copy.date, original.date);
      expect(copy.startTime, original.startTime);
      expect(copy.endTime, original.endTime);
      expect(copy.hours, original.hours);
      expect(copy.description, original.description);
      expect(copy.invoiceId, original.invoiceId);
      expect(copy.rateOverride, original.rateOverride);
    });

    test('copyWith updates date', () {
      final updated = makeEntry().copyWith(date: '2026-05-01');
      expect(updated.date, '2026-05-01');
    });

    test('copyWith updates hours', () {
      final updated = makeEntry().copyWith(hours: 4.5);
      expect(updated.hours, 4.5);
    });

    test('copyWith with clearJobId sets jobId to null', () {
      final updated = makeEntry(jobId: 'j1').copyWith(clearJobId: true);
      expect(updated.jobId, isNull);
    });

    test('copyWith with clearInvoice sets invoiceId to null', () {
      final updated = makeEntry(invoiceId: 'inv1').copyWith(clearInvoice: true);
      expect(updated.invoiceId, isNull);
    });

    test('copyWith with clearRateOverride sets rateOverride to null', () {
      final updated = makeEntry(rateOverride: 45.0).copyWith(clearRateOverride: true);
      expect(updated.rateOverride, isNull);
    });

    test('copyWith preserves id', () {
      final updated = makeEntry().copyWith(date: '2026-06-01');
      expect(updated.id, 'e1');
    });

    test('copyWith preserves unchanged fields', () {
      final updated = makeEntry().copyWith(date: '2026-06-01');
      expect(updated.jobId, 'j1');
      expect(updated.startTime, '09:00');
      expect(updated.endTime, '17:00');
      expect(updated.hours, 8.0);
      expect(updated.description, 'Fixed bug');
      expect(updated.invoiceId, 'inv1');
      expect(updated.rateOverride, 45.0);
    });
  });
}
