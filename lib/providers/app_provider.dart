import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/job.dart';
import '../models/time_entry.dart';
import '../models/invoice.dart';
import '../models/app_settings.dart';
import '../models/active_timer.dart';

const _uuid = Uuid();

class AppProvider extends ChangeNotifier {
  List<Job> jobs = [];
  List<TimeEntry> entries = [];
  List<Invoice> invoices = [];
  AppSettings settings = const AppSettings();
  List<ActiveTimer> activeTimers = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final jobsJson = prefs.getString('jobs');
    if (jobsJson != null) {
      jobs = (jsonDecode(jobsJson) as List)
          .map((e) => Job.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      jobs = _defaultJobs();
    }

    final entriesJson = prefs.getString('entries');
    if (entriesJson != null) {
      entries = (jsonDecode(entriesJson) as List)
          .map((e) => TimeEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      entries = _defaultEntries();
    }

    final invoicesJson = prefs.getString('invoices');
    if (invoicesJson != null) {
      invoices = (jsonDecode(invoicesJson) as List)
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      invoices = _defaultInvoices();
    }

    final settingsJson = prefs.getString('settings');
    if (settingsJson != null) {
      settings = AppSettings.fromJson(jsonDecode(settingsJson) as Map<String, dynamic>);
    }

    final timersJson = prefs.getString('active_timers');
    if (timersJson != null) {
      activeTimers = (jsonDecode(timersJson) as List)
          .map((e) => ActiveTimer.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jobs', jsonEncode(jobs.map((e) => e.toJson()).toList()));
    await prefs.setString('entries', jsonEncode(entries.map((e) => e.toJson()).toList()));
    await prefs.setString('invoices', jsonEncode(invoices.map((e) => e.toJson()).toList()));
    await prefs.setString('settings', jsonEncode(settings.toJson()));
    await prefs.setString('active_timers', jsonEncode(activeTimers.map((e) => e.toJson()).toList()));
  }

  // ── Jobs ──────────────────────────────────────────────────────────────────

  void addJob(String name, String description, double? rate) {
    jobs = [
      ...jobs,
      Job(
        id: _uuid.v4(),
        name: name,
        description: description,
        rate: rate,
        isArchived: false,
        createdAt: DateTime.now(),
      ),
    ];
    _save();
    notifyListeners();
  }

  void updateJob(String id, {String? name, String? description, double? rate, bool clearRate = false}) {
    jobs = jobs.map((j) {
      if (j.id != id) return j;
      return j.copyWith(name: name, description: description, rate: rate, clearRate: clearRate);
    }).toList();
    _save();
    notifyListeners();
  }

  void toggleArchiveJob(String id) {
    jobs = jobs.map((j) {
      if (j.id != id) return j;
      return j.copyWith(isArchived: !j.isArchived);
    }).toList();
    _save();
    notifyListeners();
  }

  // ── Entries ───────────────────────────────────────────────────────────────

  void addEntry({
    required String jobId,
    required String date,
    required String startTime,
    required String endTime,
    required double hours,
    required String description,
  }) {
    entries = [
      TimeEntry(
        id: _uuid.v4(),
        jobId: jobId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        hours: hours,
        description: description,
      ),
      ...entries,
    ];
    _save();
    notifyListeners();
  }

  void updateEntry(
    String id, {
    String? jobId,
    bool clearJobId = false,
    String? description,
    double? hours,
    double? rateOverride,
    bool clearRateOverride = false,
  }) {
    entries = entries.map((e) {
      if (e.id != id) return e;
      return e.copyWith(
        jobId: jobId,
        clearJobId: clearJobId,
        description: description,
        hours: hours,
        rateOverride: rateOverride,
        clearRateOverride: clearRateOverride,
      );
    }).toList();
    _save();
    notifyListeners();
  }

  void deleteEntry(String id) {
    entries = entries.where((e) => e.id != id).toList();
    _save();
    notifyListeners();
  }

  // ── Invoices ──────────────────────────────────────────────────────────────

  void createInvoice({
    required List<String> entryIds,
    required double totalHours,
    required double totalAmount,
    required String notes,
  }) {
    final num = 'INV-${(invoices.length + 1).toString().padLeft(3, '0')}';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final inv = Invoice(
      id: _uuid.v4(),
      number: num,
      createdAt: today,
      entryIds: entryIds,
      totalHours: totalHours,
      totalAmount: totalAmount,
      notes: notes,
    );
    invoices = [...invoices, inv];
    entries = entries.map((e) {
      if (!entryIds.contains(e.id)) return e;
      return e.copyWith(invoiceId: inv.id);
    }).toList();
    _save();
    notifyListeners();
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  void updateSettings(AppSettings s) {
    settings = s;
    _save();
    notifyListeners();
  }

  // ── Timers / Clock In-Out ─────────────────────────────────────────────────

  void clockIn({String? jobId, double? rateOverride}) {
    final timer = ActiveTimer(
      id: _uuid.v4(),
      jobId: jobId,
      rateOverride: rateOverride,
      startedAt: DateTime.now(),
    );
    activeTimers = [...activeTimers, timer];
    _save();
    notifyListeners();
  }

  void clockOut(String timerId) {
    final timer = activeTimers.where((t) => t.id == timerId).firstOrNull;
    if (timer == null) return;

    final now = DateTime.now();
    final elapsed = now.difference(timer.startedAt).inSeconds / 3600.0;
    final today = now.toIso8601String().substring(0, 10);
    final startStr = '${_p2(timer.startedAt.hour)}:${_p2(timer.startedAt.minute)}';
    final endStr = '${_p2(now.hour)}:${_p2(now.minute)}';

    entries = [
      TimeEntry(
        id: _uuid.v4(),
        jobId: timer.jobId,
        date: today,
        startTime: startStr,
        endTime: endStr,
        hours: elapsed,
        description: '',
        rateOverride: timer.rateOverride,
      ),
      ...entries,
    ];

    activeTimers = activeTimers.where((t) => t.id != timerId).toList();
    _save();
    notifyListeners();
  }

  void discardTimer(String timerId) {
    activeTimers = activeTimers.where((t) => t.id != timerId).toList();
    _save();
    notifyListeners();
  }

  // Convenience wrappers used by JobDetailScreen (which always has a specific jobId)
  void startTimer(String jobId) {
    if (activeTimers.any((t) => t.jobId == jobId)) return;
    clockIn(jobId: jobId);
  }

  void stopTimer(String jobId) {
    final timer = activeTimers.where((t) => t.jobId == jobId).firstOrNull;
    if (timer != null) discardTimer(timer.id);
  }

  bool isTimerRunning(String jobId) => activeTimers.any((t) => t.jobId == jobId);

  ActiveTimer? getTimer(String jobId) => activeTimers.where((t) => t.jobId == jobId).firstOrNull;

  // ── Helpers ───────────────────────────────────────────────────────────────

  double getRate(Job? job) => job?.rate ?? settings.defaultRate;

  double getEntryRate(TimeEntry entry) {
    if (entry.rateOverride != null) return entry.rateOverride!;
    final job = jobs.where((j) => j.id == entry.jobId).firstOrNull;
    return job?.rate ?? settings.defaultRate;
  }

  List<TimeEntry> get uninvoicedEntries => entries.where((e) => e.invoiceId == null).toList();

  List<TimeEntry> get invoiceableEntries =>
      entries.where((e) => e.invoiceId == null && e.jobId != null).toList();

  List<TimeEntry> get incompleteEntries =>
      entries.where((e) => e.jobId == null && e.invoiceId == null).toList();

  static String _p2(int n) => n.toString().padLeft(2, '0');

  // ── Default data ──────────────────────────────────────────────────────────

  static List<Job> _defaultJobs() {
    final now = DateTime.now();
    return [
      Job(id: 'j1', name: 'Wedding Venue Golf Cart', description: 'Maintenance & repairs', isArchived: false, createdAt: now),
      Job(id: 'j2', name: 'Wedding Venue UTV', description: 'Service & upkeep', isArchived: false, createdAt: now),
      Job(id: 'j3', name: 'Little Motorcycle', description: 'Engine & body work', rate: 40, isArchived: false, createdAt: now),
      Job(id: 'j4', name: 'Fix Cottage Sink', description: 'Drain plug repair', isArchived: false, createdAt: now),
      Job(id: 'j5', name: 'Install New Sound System', description: 'Venue audio setup', rate: 45, isArchived: false, createdAt: now),
      Job(id: 'j6', name: 'Mow Field', description: 'Regular mowing schedule', isArchived: false, createdAt: now),
      Job(id: 'j7', name: 'Cut Trees Down', description: 'Tree removal & cleanup', isArchived: false, createdAt: now),
      Job(id: 'j8', name: 'Repair Doors in Wedding Venue', description: 'Door repair & install', isArchived: false, createdAt: now),
      Job(id: 'j9', name: 'Fill In Holes in Venue Walls', description: 'Wall patching & repair', isArchived: false, createdAt: now),
      Job(id: 'j10', name: 'Fix Mower', description: 'Mower maintenance', isArchived: false, createdAt: now),
      Job(id: 'j11', name: 'Spray for Ants', description: 'Property perimeter treatment', isArchived: true, createdAt: now),
    ];
  }

  static List<TimeEntry> _defaultEntries() {
    return [
      const TimeEntry(id: 'e1',  jobId: 'j1', date: '2026-04-28', startTime: '08:00', endTime: '10:30', hours: 2.5,  description: 'Golf Cart — Replace seat covers'),
      const TimeEntry(id: 'e2',  jobId: 'j2', date: '2026-04-28', startTime: '11:00', endTime: '12:30', hours: 1.5,  description: 'UTV — Change battery'),
      const TimeEntry(id: 'e3',  jobId: 'j6', date: '2026-04-27', startTime: '07:30', endTime: '11:00', hours: 3.5,  description: 'Mowed north and east fields'),
      const TimeEntry(id: 'e4',  jobId: 'j3', date: '2026-04-26', startTime: '09:00', endTime: '13:00', hours: 4.0,  description: 'Engine tune-up, new spark plugs'),
      const TimeEntry(id: 'e5',  jobId: 'j5', date: '2026-04-25', startTime: '08:00', endTime: '16:00', hours: 8.0,  description: 'Ran speaker cables, mounted amps'),
      const TimeEntry(id: 'e6',  jobId: 'j1', date: '2026-04-24', startTime: '10:00', endTime: '11:30', hours: 1.5,  description: 'Golf Cart — Checked brakes'),
      const TimeEntry(id: 'e7',  jobId: 'j7', date: '2026-04-22', startTime: '07:00', endTime: '14:00', hours: 7.0,  description: 'Cut down 3 oaks near east fence'),
      const TimeEntry(id: 'e8',  jobId: 'j4', date: '2026-04-21', startTime: '13:00', endTime: '14:00', hours: 1.0,  description: 'Fixed drain plug in cottage bathroom'),
      const TimeEntry(id: 'e9',  jobId: 'j2', date: '2026-04-18', startTime: '09:00', endTime: '11:00', hours: 2.0,  description: 'UTV — Oil change and tire rotation', invoiceId: 'inv1'),
      const TimeEntry(id: 'e10', jobId: 'j6', date: '2026-04-15', startTime: '07:00', endTime: '10:30', hours: 3.5,  description: 'Full field mow', invoiceId: 'inv1'),
      const TimeEntry(id: 'e11', jobId: 'j1', date: '2026-04-10', startTime: '08:00', endTime: '10:00', hours: 2.0,  description: 'Golf Cart — New headlights', invoiceId: 'inv1'),
    ];
  }

  static List<Invoice> _defaultInvoices() {
    return [
      const Invoice(
        id: 'inv1',
        number: 'INV-001',
        createdAt: '2026-04-19',
        sentAt: '2026-04-19',
        entryIds: ['e9', 'e10', 'e11'],
        totalHours: 7.5,
        totalAmount: 262.50,
        notes: 'April first batch',
      ),
    ];
  }
}
