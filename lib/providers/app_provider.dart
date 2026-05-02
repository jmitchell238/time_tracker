import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/active_timer.dart';
import '../models/app_settings.dart';
import '../models/expense_item.dart';
import '../models/invoice.dart';
import '../models/job.dart';
import '../models/saved_client.dart';
import '../models/time_entry.dart';

const _uuid = Uuid();

class AppProvider extends ChangeNotifier {
  final FirebaseFirestore? _dbOverride;
  final FirebaseAuth? _authOverride;

  FirebaseFirestore? _db;
  FirebaseAuth? _auth;
  String? _workspaceId;

  List<Job> jobs = [];
  List<TimeEntry> entries = [];
  List<Invoice> invoices = [];
  List<ExpenseItem> expenses = [];
  AppSettings settings = const AppSettings();
  List<ActiveTimer> activeTimers = [];
  List<SavedClient> savedClients = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  AppProvider({FirebaseFirestore? db, FirebaseAuth? auth})
      : _dbOverride = db,
        _authOverride = auth;

  // ── Firestore helpers ─────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db!.collection('users').doc(_workspaceId!).collection(name);

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _db!.collection('users').doc(_workspaceId!).collection('config').doc('settings');

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    _db = _dbOverride ?? FirebaseFirestore.instance;
    _auth = _authOverride ?? FirebaseAuth.instance;

    final user = _auth!.currentUser;
    if (user == null) {
      _loaded = true;
      notifyListeners();
      return;
    }
    _workspaceId = user.uid;

    final results = await Future.wait([
      _col('jobs').get(),
      _col('entries').get(),
      _col('invoices').get(),
      _col('expenses').get(),
      _col('timers').get(),
      _col('savedClients').get(),
      _settingsDoc.get(),
    ]);

    final jobsDocs    = (results[0] as QuerySnapshot<Map<String, dynamic>>).docs;
    final entriesDocs = (results[1] as QuerySnapshot<Map<String, dynamic>>).docs;
    final invDocs     = (results[2] as QuerySnapshot<Map<String, dynamic>>).docs;
    final expDocs     = (results[3] as QuerySnapshot<Map<String, dynamic>>).docs;
    final timerDocs   = (results[4] as QuerySnapshot<Map<String, dynamic>>).docs;
    final clientDocs  = (results[5] as QuerySnapshot<Map<String, dynamic>>).docs;
    final settingsSnap = results[6] as DocumentSnapshot<Map<String, dynamic>>;

    // First load ever for this user → migrate from SharedPreferences
    if (jobsDocs.isEmpty && entriesDocs.isEmpty && invDocs.isEmpty) {
      await _migrateFromSharedPreferences();
      _loaded = true;
      notifyListeners();
      return;
    }

    jobs        = jobsDocs.map((d)    => Job.fromJson(d.data())).toList();
    entries     = entriesDocs.map((d) => TimeEntry.fromJson(d.data())).toList();
    invoices    = invDocs.map((d)     => Invoice.fromJson(d.data())).toList();
    expenses    = expDocs.map((d)     => ExpenseItem.fromJson(d.data())).toList();
    activeTimers = timerDocs.map((d)  => ActiveTimer.fromJson(d.data())).toList();
    savedClients = clientDocs.map((d) => SavedClient.fromJson(d.data())).toList();
    if (settingsSnap.exists && settingsSnap.data() != null) {
      settings = AppSettings.fromJson(settingsSnap.data()!);
    }

    _loaded = true;
    notifyListeners();
  }

  // ── Migration from SharedPreferences ──────────────────────────────────────

  Future<void> _migrateFromSharedPreferences() async {
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
      settings = AppSettings.fromJson(
          jsonDecode(settingsJson) as Map<String, dynamic>);
    }

    final timersJson = prefs.getString('active_timers');
    if (timersJson != null) {
      activeTimers = (jsonDecode(timersJson) as List)
          .map((e) => ActiveTimer.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final expensesJson = prefs.getString('expenses');
    if (expensesJson != null) {
      expenses = (jsonDecode(expensesJson) as List)
          .map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final clientsJson = prefs.getString('saved_clients');
    if (clientsJson != null) {
      savedClients = (jsonDecode(clientsJson) as List)
          .map((e) => SavedClient.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final batch = _db!.batch();
    for (final j in jobs) batch.set(_col('jobs').doc(j.id), j.toJson());
    for (final e in entries) batch.set(_col('entries').doc(e.id), e.toJson());
    for (final i in invoices) batch.set(_col('invoices').doc(i.id), i.toJson());
    for (final e in expenses) batch.set(_col('expenses').doc(e.id), e.toJson());
    for (final t in activeTimers) batch.set(_col('timers').doc(t.id), t.toJson());
    for (final c in savedClients) batch.set(_col('savedClients').doc(c.id), c.toJson());
    batch.set(_settingsDoc, settings.toJson());
    await batch.commit();
  }

  // ── Jobs ──────────────────────────────────────────────────────────────────

  void addJob(String name, String description, double? rate) {
    final job = Job(
      id: _uuid.v4(),
      name: name,
      description: description,
      rate: rate,
      isArchived: false,
      createdAt: DateTime.now(),
    );
    jobs = [...jobs, job];
    if (_workspaceId != null) {
      _col('jobs').doc(job.id).set(job.toJson());
    }
    notifyListeners();
  }

  void updateJob(String id, {String? name, String? description, double? rate, bool clearRate = false}) {
    jobs = jobs.map((j) {
      if (j.id != id) return j;
      return j.copyWith(name: name, description: description, rate: rate, clearRate: clearRate);
    }).toList();
    final updated = jobs.firstWhere((j) => j.id == id);
    if (_workspaceId != null) {
      _col('jobs').doc(id).set(updated.toJson());
    }
    notifyListeners();
  }

  void toggleArchiveJob(String id) {
    jobs = jobs.map((j) {
      if (j.id != id) return j;
      return j.copyWith(isArchived: !j.isArchived);
    }).toList();
    final updated = jobs.firstWhere((j) => j.id == id);
    if (_workspaceId != null) {
      _col('jobs').doc(id).set(updated.toJson());
    }
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
    final entry = TimeEntry(
      id: _uuid.v4(),
      jobId: jobId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      hours: hours,
      description: description,
    );
    entries = [entry, ...entries];
    if (_workspaceId != null) {
      _col('entries').doc(entry.id).set(entry.toJson());
    }
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
    final updated = entries.firstWhere((e) => e.id == id);
    if (_workspaceId != null) {
      _col('entries').doc(id).set(updated.toJson());
    }
    notifyListeners();
  }

  void deleteEntry(String id) {
    entries = entries.where((e) => e.id != id).toList();
    if (_workspaceId != null) {
      _col('entries').doc(id).delete();
    }
    notifyListeners();
  }

  // ── Invoices ──────────────────────────────────────────────────────────────

  void createInvoice({
    required List<String> entryIds,
    List<String> expenseIds = const [],
    required double totalHours,
    required double totalAmount,
    double expensesTotal = 0,
    required String notes,
    String? clientName,
    String? clientCompany,
    String? clientPhone,
    String? billedBy,
  }) {
    final num = 'INV-${(invoices.length + 1).toString().padLeft(3, '0')}';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final inv = Invoice(
      id: _uuid.v4(),
      number: num,
      createdAt: today,
      entryIds: entryIds,
      expenseIds: expenseIds,
      totalHours: totalHours,
      totalAmount: totalAmount,
      expensesTotal: expensesTotal,
      notes: notes,
      clientName: clientName?.isEmpty == true ? null : clientName,
      clientCompany: clientCompany?.isEmpty == true ? null : clientCompany,
      clientPhone: clientPhone?.isEmpty == true ? null : clientPhone,
      billedBy: billedBy,
    );
    invoices = [...invoices, inv];

    SavedClient? newClient;
    if (clientCompany != null || clientName != null) {
      final alreadySaved = savedClients.any((c) =>
          c.company == (clientCompany?.isEmpty == true ? null : clientCompany) &&
          c.name == (clientName?.isEmpty == true ? null : clientName));
      if (!alreadySaved) {
        newClient = SavedClient(
          id: _uuid.v4(),
          name: clientName?.isEmpty == true ? null : clientName,
          company: clientCompany?.isEmpty == true ? null : clientCompany,
          phone: clientPhone?.isEmpty == true ? null : clientPhone,
        );
        savedClients = [...savedClients, newClient];
      }
    }

    entries = entries.map((e) {
      if (!entryIds.contains(e.id)) return e;
      return e.copyWith(invoiceId: inv.id);
    }).toList();
    expenses = expenses.map((e) {
      if (!expenseIds.contains(e.id)) return e;
      return e.copyWith(invoiceId: inv.id);
    }).toList();

    if (_workspaceId != null) {
      final batch = _db!.batch();
      batch.set(_col('invoices').doc(inv.id), inv.toJson());
      for (final e in entries.where((e) => entryIds.contains(e.id))) {
        batch.set(_col('entries').doc(e.id), e.toJson());
      }
      for (final e in expenses.where((e) => expenseIds.contains(e.id))) {
        batch.set(_col('expenses').doc(e.id), e.toJson());
      }
      if (newClient != null) {
        batch.set(_col('savedClients').doc(newClient.id), newClient.toJson());
      }
      batch.commit();
    }
    notifyListeners();
  }

  void markInvoicePaid(String id,
      {required String paidAt, required String paymentMethod}) {
    invoices = invoices.map((inv) {
      if (inv.id != id) return inv;
      return inv.copyWith(paidAt: paidAt, paymentMethod: paymentMethod);
    }).toList();
    final updated = invoices.firstWhere((i) => i.id == id);
    if (_workspaceId != null) {
      _col('invoices').doc(id).set(updated.toJson());
    }
    notifyListeners();
  }

  void unmarkInvoicePaid(String id) {
    invoices = invoices.map((inv) {
      if (inv.id != id) return inv;
      return inv.copyWith(clearPaidAt: true, clearPaymentMethod: true);
    }).toList();
    final updated = invoices.firstWhere((i) => i.id == id);
    if (_workspaceId != null) {
      _col('invoices').doc(id).set(updated.toJson());
    }
    notifyListeners();
  }

  void deleteInvoice(String id) {
    final inv = invoices.where((i) => i.id == id).firstOrNull;
    if (inv == null) return;
    entries = entries.map((e) {
      if (e.invoiceId != id) return e;
      return e.copyWith(clearInvoice: true);
    }).toList();
    expenses = expenses.map((e) {
      if (e.invoiceId != id) return e;
      return e.copyWith(clearInvoiceId: true);
    }).toList();
    invoices = invoices.where((i) => i.id != id).toList();

    if (_workspaceId != null) {
      final batch = _db!.batch();
      batch.delete(_col('invoices').doc(id));
      for (final e in entries.where((e) => inv.entryIds.contains(e.id))) {
        batch.set(_col('entries').doc(e.id), e.toJson());
      }
      for (final e in expenses.where((e) => inv.expenseIds.contains(e.id))) {
        batch.set(_col('expenses').doc(e.id), e.toJson());
      }
      batch.commit();
    }
    notifyListeners();
  }

  // ── Saved Clients ─────────────────────────────────────────────────────────

  void addSavedClient({String? name, String? company, String? phone}) {
    final client = SavedClient(
        id: _uuid.v4(), name: name, company: company, phone: phone);
    savedClients = [...savedClients, client];
    if (_workspaceId != null) {
      _col('savedClients').doc(client.id).set(client.toJson());
    }
    notifyListeners();
  }

  void deleteSavedClient(String id) {
    savedClients = savedClients.where((c) => c.id != id).toList();
    if (_workspaceId != null) {
      _col('savedClients').doc(id).delete();
    }
    notifyListeners();
  }

  void addPaymentMethod(String method) {
    if (settings.paymentMethods.contains(method)) return;
    settings = settings.copyWith(
      paymentMethods: [...settings.paymentMethods, method],
    );
    if (_workspaceId != null) {
      _settingsDoc.set(settings.toJson());
    }
    notifyListeners();
  }

  // ── Expenses ──────────────────────────────────────────────────────────────

  void addExpense({
    required String description,
    required double amount,
    required String date,
    required String purchasedBy,
  }) {
    final expense = ExpenseItem(
      id: _uuid.v4(),
      description: description,
      amount: amount,
      date: date,
      purchasedBy: purchasedBy,
    );
    expenses = [expense, ...expenses];
    if (_workspaceId != null) {
      _col('expenses').doc(expense.id).set(expense.toJson());
    }
    notifyListeners();
  }

  void deleteExpense(String id) {
    expenses = expenses.where((e) => e.id != id).toList();
    if (_workspaceId != null) {
      _col('expenses').doc(id).delete();
    }
    notifyListeners();
  }

  List<ExpenseItem> get uninvoicedExpenses =>
      expenses.where((e) => e.invoiceId == null).toList();

  // ── Settings ──────────────────────────────────────────────────────────────

  void updateSettings(AppSettings s) {
    settings = s;
    if (_workspaceId != null) {
      _settingsDoc.set(s.toJson());
    }
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
    if (_workspaceId != null) {
      _col('timers').doc(timer.id).set(timer.toJson());
    }
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

    final entry = TimeEntry(
      id: _uuid.v4(),
      jobId: timer.jobId,
      date: today,
      startTime: startStr,
      endTime: endStr,
      hours: elapsed,
      description: '',
      rateOverride: timer.rateOverride,
    );
    entries = [entry, ...entries];
    activeTimers = activeTimers.where((t) => t.id != timerId).toList();

    if (_workspaceId != null) {
      final batch = _db!.batch();
      batch.delete(_col('timers').doc(timerId));
      batch.set(_col('entries').doc(entry.id), entry.toJson());
      batch.commit();
    }
    notifyListeners();
  }

  void discardTimer(String timerId) {
    activeTimers = activeTimers.where((t) => t.id != timerId).toList();
    if (_workspaceId != null) {
      _col('timers').doc(timerId).delete();
    }
    notifyListeners();
  }

  void startTimer(String jobId) {
    if (activeTimers.any((t) => t.jobId == jobId)) return;
    clockIn(jobId: jobId);
  }

  void stopTimer(String jobId) {
    final timer = activeTimers.where((t) => t.jobId == jobId).firstOrNull;
    if (timer != null) discardTimer(timer.id);
  }

  bool isTimerRunning(String jobId) =>
      activeTimers.any((t) => t.jobId == jobId);

  ActiveTimer? getTimer(String jobId) =>
      activeTimers.where((t) => t.jobId == jobId).firstOrNull;

  // ── Helpers ───────────────────────────────────────────────────────────────

  double getRate(Job? job) => job?.rate ?? settings.defaultRate;

  double getEntryRate(TimeEntry entry) {
    if (entry.rateOverride != null) return entry.rateOverride!;
    final job = jobs.where((j) => j.id == entry.jobId).firstOrNull;
    return job?.rate ?? settings.defaultRate;
  }

  List<TimeEntry> get uninvoicedEntries =>
      entries.where((e) => e.invoiceId == null).toList();

  List<TimeEntry> get invoiceableEntries =>
      entries.where((e) => e.invoiceId == null && e.jobId != null).toList();

  List<TimeEntry> get incompleteEntries =>
      entries.where((e) => e.jobId == null && e.invoiceId == null).toList();

  static String _p2(int n) => n.toString().padLeft(2, '0');

  // ── Default data (used during migration for brand-new accounts) ───────────

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
