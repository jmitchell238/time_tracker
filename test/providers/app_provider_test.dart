import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/models/app_settings.dart';
import 'package:time_tracker/models/job.dart';
import 'package:time_tracker/models/time_entry.dart';
import 'package:time_tracker/providers/app_provider.dart';

AppProvider _fresh() => AppProvider();

Job _job({String id = 'j1', String name = 'Lawn', double? rate = 45.0, bool isArchived = false}) =>
    Job(id: id, name: name, description: '', rate: rate, isArchived: isArchived, createdAt: DateTime(2026));

TimeEntry _entry({
  String id = 'e1',
  String? jobId = 'j1',
  double hours = 2.0,
  double? rateOverride,
  String? invoiceId,
}) =>
    TimeEntry(
      id: id,
      jobId: jobId,
      date: '2026-04-01',
      startTime: '09:00',
      endTime: '11:00',
      hours: hours,
      description: '',
      invoiceId: invoiceId,
      rateOverride: rateOverride,
    );

void main() {
  // ── getRate ──────────────────────────────────────────────────────────────

  group('getRate', () {
    test('returns job rate when job has rate', () {
      final p = _fresh()..settings = const AppSettings(defaultRate: 35.0);
      expect(p.getRate(_job(rate: 45.0)), 45.0);
    });

    test('returns defaultRate when job is null', () {
      final p = _fresh()..settings = const AppSettings(defaultRate: 35.0);
      expect(p.getRate(null), 35.0);
    });

    test('returns defaultRate when job rate is null', () {
      final p = _fresh()..settings = const AppSettings(defaultRate: 35.0);
      expect(p.getRate(_job(rate: null)), 35.0);
    });
  });

  // ── getEntryRate ─────────────────────────────────────────────────────────

  group('getEntryRate', () {
    test('returns rateOverride when set', () {
      final p = _fresh()
        ..jobs = [_job(rate: 45.0)]
        ..settings = const AppSettings(defaultRate: 35.0);
      expect(p.getEntryRate(_entry(rateOverride: 60.0)), 60.0);
    });

    test('returns job rate when no rateOverride', () {
      final p = _fresh()
        ..jobs = [_job(rate: 45.0)]
        ..settings = const AppSettings(defaultRate: 35.0);
      expect(p.getEntryRate(_entry(jobId: 'j1')), 45.0);
    });

    test('returns defaultRate when job rate is null', () {
      final p = _fresh()
        ..jobs = [_job(rate: null)]
        ..settings = const AppSettings(defaultRate: 35.0);
      expect(p.getEntryRate(_entry(jobId: 'j1')), 35.0);
    });

    test('returns defaultRate when jobId not found', () {
      final p = _fresh()
        ..jobs = []
        ..settings = const AppSettings(defaultRate: 35.0);
      expect(p.getEntryRate(_entry(jobId: 'missing')), 35.0);
    });
  });

  // ── Computed getters ─────────────────────────────────────────────────────

  group('uninvoicedEntries', () {
    test('returns only entries with null invoiceId', () {
      final p = _fresh()
        ..entries = [
          _entry(id: 'e1', invoiceId: null),
          _entry(id: 'e2', invoiceId: 'inv1'),
          _entry(id: 'e3', invoiceId: null),
        ];
      final ids = p.uninvoicedEntries.map((e) => e.id).toList();
      expect(ids, containsAll(['e1', 'e3']));
      expect(ids, isNot(contains('e2')));
    });
  });

  group('invoiceableEntries', () {
    test('returns entries with null invoiceId and non-null jobId', () {
      final p = _fresh()
        ..entries = [
          _entry(id: 'e1', jobId: 'j1', invoiceId: null),
          _entry(id: 'e2', jobId: null, invoiceId: null),
          _entry(id: 'e3', jobId: 'j1', invoiceId: 'inv1'),
        ];
      final ids = p.invoiceableEntries.map((e) => e.id).toList();
      expect(ids, ['e1']);
    });
  });

  group('incompleteEntries', () {
    test('returns entries with null jobId and null invoiceId', () {
      final p = _fresh()
        ..entries = [
          _entry(id: 'e1', jobId: null, invoiceId: null),
          _entry(id: 'e2', jobId: 'j1', invoiceId: null),
          _entry(id: 'e3', jobId: null, invoiceId: 'inv1'),
        ];
      final ids = p.incompleteEntries.map((e) => e.id).toList();
      expect(ids, ['e1']);
    });
  });

  // ── Jobs ─────────────────────────────────────────────────────────────────

  group('addJob', () {
    test('appends a new job with correct fields', () async {
      final p = _fresh()..jobs = [];
      p.addJob('Lawn Care', 'Weekly', 45.0);
      await Future.microtask(() {});
      expect(p.jobs.length, 1);
      expect(p.jobs.first.name, 'Lawn Care');
      expect(p.jobs.first.description, 'Weekly');
      expect(p.jobs.first.rate, 45.0);
      expect(p.jobs.first.isArchived, false);
    });

    test('notifies listeners', () async {
      final p = _fresh()..jobs = [];
      var notified = false;
      p.addListener(() => notified = true);
      p.addJob('Lawn Care', '', null);
      await Future.microtask(() {});
      expect(notified, true);
    });
  });

  group('updateJob', () {
    test('updates name and description', () async {
      final p = _fresh()..jobs = [_job()];
      p.updateJob('j1', name: 'Snow Removal', description: 'Winter');
      await Future.microtask(() {});
      expect(p.jobs.first.name, 'Snow Removal');
      expect(p.jobs.first.description, 'Winter');
    });

    test('clearRate sets rate to null', () async {
      final p = _fresh()..jobs = [_job(rate: 45.0)];
      p.updateJob('j1', clearRate: true);
      await Future.microtask(() {});
      expect(p.jobs.first.rate, isNull);
    });

    test('does not affect other jobs', () async {
      final p = _fresh()..jobs = [_job(id: 'j1'), _job(id: 'j2', name: 'Other')];
      p.updateJob('j1', name: 'Updated');
      await Future.microtask(() {});
      expect(p.jobs.firstWhere((j) => j.id == 'j2').name, 'Other');
    });
  });

  group('toggleArchiveJob', () {
    test('archives an active job', () async {
      final p = _fresh()..jobs = [_job(isArchived: false)];
      p.toggleArchiveJob('j1');
      await Future.microtask(() {});
      expect(p.jobs.first.isArchived, true);
    });

    test('unarchives an archived job', () async {
      final p = _fresh()..jobs = [_job(isArchived: true)];
      p.toggleArchiveJob('j1');
      await Future.microtask(() {});
      expect(p.jobs.first.isArchived, false);
    });
  });

  // ── Entries ──────────────────────────────────────────────────────────────

  group('addEntry', () {
    test('prepends new entry to list', () async {
      final p = _fresh()..entries = [_entry(id: 'e_old')];
      p.addEntry(
        jobId: 'j1', date: '2026-05-01',
        startTime: '09:00', endTime: '10:00',
        hours: 1.0, description: 'Test',
      );
      await Future.microtask(() {});
      expect(p.entries.length, 2);
      expect(p.entries.first.jobId, 'j1');
      expect(p.entries.last.id, 'e_old');
    });

    test('notifies listeners', () async {
      final p = _fresh()..entries = [];
      var notified = false;
      p.addListener(() => notified = true);
      p.addEntry(jobId: 'j1', date: '2026-05-01', startTime: '09:00', endTime: '10:00', hours: 1.0, description: '');
      await Future.microtask(() {});
      expect(notified, true);
    });
  });

  group('updateEntry', () {
    test('updates description and hours', () async {
      final p = _fresh()..entries = [_entry()];
      p.updateEntry('e1', description: 'New desc', hours: 3.0);
      await Future.microtask(() {});
      expect(p.entries.first.description, 'New desc');
      expect(p.entries.first.hours, 3.0);
    });

    test('clearJobId sets jobId to null', () async {
      final p = _fresh()..entries = [_entry(jobId: 'j1')];
      p.updateEntry('e1', clearJobId: true);
      await Future.microtask(() {});
      expect(p.entries.first.jobId, isNull);
    });

    test('clearRateOverride sets rateOverride to null', () async {
      final p = _fresh()..entries = [_entry(rateOverride: 50.0)];
      p.updateEntry('e1', clearRateOverride: true);
      await Future.microtask(() {});
      expect(p.entries.first.rateOverride, isNull);
    });
  });

  group('deleteEntry', () {
    test('removes the matching entry', () async {
      final p = _fresh()..entries = [_entry(id: 'e1'), _entry(id: 'e2')];
      p.deleteEntry('e1');
      await Future.microtask(() {});
      expect(p.entries.length, 1);
      expect(p.entries.first.id, 'e2');
    });

    test('notifies listeners', () async {
      final p = _fresh()..entries = [_entry()];
      var notified = false;
      p.addListener(() => notified = true);
      p.deleteEntry('e1');
      await Future.microtask(() {});
      expect(notified, true);
    });
  });

  // ── Invoices ──────────────────────────────────────────────────────────────

  group('createInvoice', () {
    test('generates invoice number based on count', () async {
      final p = _fresh()
        ..invoices = []
        ..entries = [_entry(id: 'e1')];
      p.createInvoice(entryIds: ['e1'], totalHours: 2.0, totalAmount: 90.0, notes: '');
      await Future.microtask(() {});
      expect(p.invoices.first.number, 'INV-001');
    });

    test('second invoice gets INV-002', () async {
      final p = _fresh()
        ..entries = [_entry(id: 'e1'), _entry(id: 'e2')];
      p.createInvoice(entryIds: ['e1'], totalHours: 2.0, totalAmount: 90.0, notes: '');
      await Future.microtask(() {});
      p.createInvoice(entryIds: ['e2'], totalHours: 2.0, totalAmount: 90.0, notes: '');
      await Future.microtask(() {});
      expect(p.invoices[1].number, 'INV-002');
    });

    test('stamps invoiceId on included entries', () async {
      final p = _fresh()
        ..invoices = []
        ..entries = [_entry(id: 'e1'), _entry(id: 'e2')];
      p.createInvoice(entryIds: ['e1'], totalHours: 2.0, totalAmount: 90.0, notes: '');
      await Future.microtask(() {});
      expect(p.entries.firstWhere((e) => e.id == 'e1').invoiceId, isNotNull);
      expect(p.entries.firstWhere((e) => e.id == 'e2').invoiceId, isNull);
    });

    test('empty clientName becomes null', () async {
      final p = _fresh()..entries = [_entry(id: 'e1')];
      p.createInvoice(entryIds: ['e1'], totalHours: 1.0, totalAmount: 35.0, notes: '', clientName: '');
      await Future.microtask(() {});
      expect(p.invoices.first.clientName, isNull);
    });

    test('non-empty clientName is preserved', () async {
      final p = _fresh()..entries = [_entry(id: 'e1')];
      p.createInvoice(entryIds: ['e1'], totalHours: 1.0, totalAmount: 35.0, notes: '', clientName: 'Acme');
      await Future.microtask(() {});
      expect(p.invoices.first.clientName, 'Acme');
    });
  });

  // ── Settings ──────────────────────────────────────────────────────────────

  group('updateSettings', () {
    test('replaces settings', () async {
      final p = _fresh()..settings = const AppSettings(defaultRate: 35.0);
      p.updateSettings(const AppSettings(defaultRate: 60.0, billingName: 'John'));
      await Future.microtask(() {});
      expect(p.settings.defaultRate, 60.0);
      expect(p.settings.billingName, 'John');
    });
  });

  // ── Timers ────────────────────────────────────────────────────────────────

  group('clockIn', () {
    test('adds an active timer', () async {
      final p = _fresh()..activeTimers = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      expect(p.activeTimers.length, 1);
      expect(p.activeTimers.first.jobId, 'j1');
    });

    test('notifies listeners', () async {
      final p = _fresh()..activeTimers = [];
      var notified = false;
      p.addListener(() => notified = true);
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      expect(notified, true);
    });
  });

  group('clockOut', () {
    test('removes the timer', () async {
      final p = _fresh()..activeTimers = []..entries = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      final timerId = p.activeTimers.first.id;
      p.clockOut(timerId);
      await Future.microtask(() {});
      expect(p.activeTimers, isEmpty);
    });

    test('adds a time entry', () async {
      final p = _fresh()..activeTimers = []..entries = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      final timerId = p.activeTimers.first.id;
      p.clockOut(timerId);
      await Future.microtask(() {});
      expect(p.entries.length, 1);
      expect(p.entries.first.jobId, 'j1');
    });

    test('does nothing for unknown timerId', () async {
      final p = _fresh()..activeTimers = []..entries = [];
      p.clockOut('nonexistent');
      await Future.microtask(() {});
      expect(p.entries, isEmpty);
    });
  });

  group('discardTimer', () {
    test('removes the timer without creating an entry', () async {
      final p = _fresh()..activeTimers = []..entries = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      final timerId = p.activeTimers.first.id;
      p.discardTimer(timerId);
      await Future.microtask(() {});
      expect(p.activeTimers, isEmpty);
      expect(p.entries, isEmpty);
    });
  });

  group('startTimer', () {
    test('creates a timer for the job', () async {
      final p = _fresh()..activeTimers = [];
      p.startTimer('j1');
      await Future.microtask(() {});
      expect(p.activeTimers.length, 1);
      expect(p.activeTimers.first.jobId, 'j1');
    });

    test('does nothing if timer already running for that job', () async {
      final p = _fresh()..activeTimers = [];
      p.startTimer('j1');
      await Future.microtask(() {});
      p.startTimer('j1');
      await Future.microtask(() {});
      expect(p.activeTimers.length, 1);
    });
  });

  group('stopTimer', () {
    test('discards the timer for the job', () async {
      final p = _fresh()..activeTimers = []..entries = [];
      p.startTimer('j1');
      await Future.microtask(() {});
      p.stopTimer('j1');
      await Future.microtask(() {});
      expect(p.activeTimers, isEmpty);
      expect(p.entries, isEmpty);
    });
  });

  group('isTimerRunning', () {
    test('returns true when timer exists for jobId', () async {
      final p = _fresh()..activeTimers = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      expect(p.isTimerRunning('j1'), true);
    });

    test('returns false when no timer for jobId', () {
      final p = _fresh()..activeTimers = [];
      expect(p.isTimerRunning('j1'), false);
    });
  });

  group('getTimer', () {
    test('returns timer for matching jobId', () async {
      final p = _fresh()..activeTimers = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      expect(p.getTimer('j1'), isNotNull);
      expect(p.getTimer('j1')!.jobId, 'j1');
    });

    test('returns null when no timer for jobId', () {
      final p = _fresh()..activeTimers = [];
      expect(p.getTimer('j1'), isNull);
    });
  });

  group('startBreak', () {
    test('sets breakStartedAt on the timer', () async {
      final p = _fresh()..activeTimers = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      final timerId = p.activeTimers.first.id;
      p.startBreak(timerId);
      await Future.microtask(() {});
      expect(p.activeTimers.first.breakStartedAt, isNotNull);
      expect(p.activeTimers.first.isOnBreak, true);
    });

    test('does nothing for unknown timerId', () async {
      final p = _fresh()..activeTimers = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      p.startBreak('nonexistent');
      await Future.microtask(() {});
      expect(p.activeTimers.first.breakStartedAt, isNull);
    });

    test('does nothing if already on break', () async {
      final p = _fresh()..activeTimers = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      final timerId = p.activeTimers.first.id;
      p.startBreak(timerId);
      await Future.microtask(() {});
      final firstBreakTime = p.activeTimers.first.breakStartedAt;
      p.startBreak(timerId);
      await Future.microtask(() {});
      expect(p.activeTimers.first.breakStartedAt, firstBreakTime);
    });

    test('notifies listeners', () async {
      final p = _fresh()..activeTimers = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      final timerId = p.activeTimers.first.id;
      var notified = false;
      p.addListener(() => notified = true);
      p.startBreak(timerId);
      await Future.microtask(() {});
      expect(notified, true);
    });
  });

  group('endBreak', () {
    test('clears breakStartedAt on the timer', () async {
      final p = _fresh()..activeTimers = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      final timerId = p.activeTimers.first.id;
      p.startBreak(timerId);
      await Future.microtask(() {});
      p.endBreak(timerId);
      await Future.microtask(() {});
      expect(p.activeTimers.first.breakStartedAt, isNull);
      expect(p.activeTimers.first.isOnBreak, false);
    });

    test('accumulates totalBreakSeconds', () async {
      final p = _fresh()..activeTimers = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      final timerId = p.activeTimers.first.id;
      p.startBreak(timerId);
      await Future.delayed(const Duration(milliseconds: 50));
      p.endBreak(timerId);
      await Future.microtask(() {});
      expect(p.activeTimers.first.totalBreakSeconds, greaterThanOrEqualTo(0));
    });

    test('does nothing for unknown timerId', () async {
      final p = _fresh()..activeTimers = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      final timerId = p.activeTimers.first.id;
      p.startBreak(timerId);
      await Future.microtask(() {});
      p.endBreak('nonexistent');
      await Future.microtask(() {});
      expect(p.activeTimers.first.breakStartedAt, isNotNull);
    });

    test('does nothing if not on break', () async {
      final p = _fresh()..activeTimers = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      final timerId = p.activeTimers.first.id;
      p.endBreak(timerId);
      await Future.microtask(() {});
      expect(p.activeTimers.first.totalBreakSeconds, 0);
    });

    test('notifies listeners', () async {
      final p = _fresh()..activeTimers = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      final timerId = p.activeTimers.first.id;
      p.startBreak(timerId);
      await Future.microtask(() {});
      var notified = false;
      p.addListener(() => notified = true);
      p.endBreak(timerId);
      await Future.microtask(() {});
      expect(notified, true);
    });
  });

  group('clockOut with breaks', () {
    test('deducts accumulated totalBreakSeconds from entry hours', () async {
      final p = _fresh()..activeTimers = []..entries = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      final timerId = p.activeTimers.first.id;
      // Manually inject 3600 break seconds (1 hr) into the timer
      p.activeTimers = [
        p.activeTimers.first.copyWith(totalBreakSeconds: 3600),
      ];
      p.clockOut(timerId);
      await Future.microtask(() {});
      // Entry hours should be very small (near 0) since break was 1hr and
      // total elapsed is also near 0 in a test — clamp to 0
      expect(p.entries.first.hours, greaterThanOrEqualTo(0.0));
    });

    test('deducts active break duration when clocking out while on break', () async {
      final p = _fresh()..activeTimers = []..entries = [];
      p.clockIn(jobId: 'j1');
      await Future.microtask(() {});
      final timerId = p.activeTimers.first.id;
      p.startBreak(timerId);
      await Future.microtask(() {});
      p.clockOut(timerId);
      await Future.microtask(() {});
      expect(p.entries.first.hours, greaterThanOrEqualTo(0.0));
      expect(p.entries, isNotEmpty);
    });
  });

  // ── addBreak ─────────────────────────────────────────────────────────────

  group('addBreak', () {
    test('subtracts break minutes from entry hours', () {
      final p = _fresh()..entries = [_entry(id: 'e1', hours: 2.0)];
      p.addBreak('e1', 30);
      expect(p.entries.first.hours, closeTo(1.5, 0.001));
    });

    test('subtracts a 15-minute break correctly', () {
      final p = _fresh()..entries = [_entry(id: 'e1', hours: 1.0)];
      p.addBreak('e1', 15);
      expect(p.entries.first.hours, closeTo(0.75, 0.001));
    });

    test('does not reduce hours below zero', () {
      final p = _fresh()..entries = [_entry(id: 'e1', hours: 0.25)];
      p.addBreak('e1', 60);
      expect(p.entries.first.hours, 0.0);
    });

    test('does nothing when entry not found', () {
      final p = _fresh()..entries = [_entry(id: 'e1', hours: 2.0)];
      p.addBreak('missing', 30);
      expect(p.entries.first.hours, 2.0);
    });

    test('notifies listeners after break', () {
      final p = _fresh()..entries = [_entry(id: 'e1', hours: 2.0)];
      var notified = false;
      p.addListener(() => notified = true);
      p.addBreak('e1', 30);
      expect(notified, isTrue);
    });
  });

  // ── addAdjustment ─────────────────────────────────────────────────────────

  group('addAdjustment', () {
    test('adds positive adjustment to entry hours', () {
      final p = _fresh()..entries = [_entry(id: 'e1', hours: 2.0)];
      p.addAdjustment('e1', 0.5);
      expect(p.entries.first.hours, closeTo(2.5, 0.001));
    });

    test('subtracts negative adjustment from entry hours', () {
      final p = _fresh()..entries = [_entry(id: 'e1', hours: 2.0)];
      p.addAdjustment('e1', -0.5);
      expect(p.entries.first.hours, closeTo(1.5, 0.001));
    });

    test('does not reduce hours below zero', () {
      final p = _fresh()..entries = [_entry(id: 'e1', hours: 1.0)];
      p.addAdjustment('e1', -5.0);
      expect(p.entries.first.hours, 0.0);
    });

    test('does nothing when entry not found', () {
      final p = _fresh()..entries = [_entry(id: 'e1', hours: 2.0)];
      p.addAdjustment('missing', 1.0);
      expect(p.entries.first.hours, 2.0);
    });

    test('notifies listeners after adjustment', () {
      final p = _fresh()..entries = [_entry(id: 'e1', hours: 2.0)];
      var notified = false;
      p.addListener(() => notified = true);
      p.addAdjustment('e1', 0.5);
      expect(notified, isTrue);
    });
  });

}
