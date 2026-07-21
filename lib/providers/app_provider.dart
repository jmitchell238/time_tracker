import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/active_timer.dart';
import '../models/app_settings.dart';
import '../models/entry_category.dart';
import '../models/expense_item.dart';
import '../models/invoice.dart';
import '../models/job.dart';
import '../models/business.dart';
import '../models/time_entry.dart';
import '../services/analytics_service.dart';
import '../services/badge_service.dart';
import '../services/csv_import_service.dart';

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
  List<Business> businesses = [];
  List<EntryCategory> categories = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  String get currentUserFirstName {
    final email = (_auth ?? _authOverride ?? FirebaseAuth.instance).currentUser?.email ?? '';
    if (email == 'jmitchell238@gmail.com') return 'James';
    if (email == 'wlmitchell238@gmail.com') return 'Whitney';
    final local = email.split('@').first;
    return local.isEmpty ? 'there' : local[0].toUpperCase() + local.substring(1);
  }

  ThemeMode get resolvedThemeMode {
    switch (settings.themeMode) {
      case 'dark':   return ThemeMode.dark;
      case 'light':  return ThemeMode.light;
      default:       return ThemeMode.system;
    }
  }

  AppProvider({FirebaseFirestore? db, FirebaseAuth? auth})
      : _dbOverride = db,
        _authOverride = auth;

  @override
  void notifyListeners() {
    setBadgeCount(activeTimers.length);
    super.notifyListeners();
  }

  // ── Firestore helpers ─────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db!.collection('users').doc(_workspaceId!).collection(name);

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _db!.collection('users').doc(_workspaceId!).collection('config').doc('settings');

  DocumentReference<Map<String, dynamic>> get _migrationSentinel =>
      _db!.collection('users').doc(_workspaceId!).collection('config').doc('migrated');

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
    Analytics.identify(user.uid, email: user.email);

    // Resolve workspace — any authenticated user shares the same workspace.
    // Falls back to the current user's uid if the config doc is unreachable,
    // so data reads/writes always have a valid path.
    try {
      final wsRef = _db!.collection('config').doc('workspace');
      final wsSnap = await wsRef.get();
      if (wsSnap.exists) {
        _workspaceId = wsSnap.data()!['primaryUid'] as String;
      } else {
        _workspaceId = user.uid;
        await wsRef.set({'primaryUid': user.uid});
      }
    } catch (e) {
      debugPrint('Workspace lookup failed, falling back to own uid: $e');
      _workspaceId = user.uid;
    }

    try {
      final results = await Future.wait([
        _col('jobs').get(),
        _col('entries').get(),
        _col('invoices').get(),
        _col('expenses').get(),
        _col('timers').get(),
        _col('businesses').get(),
        _settingsDoc.get(),
        _migrationSentinel.get(),
        _col('categories').get(),
      ]);

      final jobsDocs    = (results[0] as QuerySnapshot<Map<String, dynamic>>).docs;
      final entriesDocs = (results[1] as QuerySnapshot<Map<String, dynamic>>).docs;
      final invDocs     = (results[2] as QuerySnapshot<Map<String, dynamic>>).docs;
      final expDocs     = (results[3] as QuerySnapshot<Map<String, dynamic>>).docs;
      final timerDocs   = (results[4] as QuerySnapshot<Map<String, dynamic>>).docs;
      final clientDocs  = (results[5] as QuerySnapshot<Map<String, dynamic>>).docs;
      final settingsSnap   = results[6] as DocumentSnapshot<Map<String, dynamic>>;
      final sentinelSnap   = results[7] as DocumentSnapshot<Map<String, dynamic>>;
      final categoryDocs   = (results[8] as QuerySnapshot<Map<String, dynamic>>).docs;
      final alreadyMigrated = sentinelSnap.exists;

      // Only migrate on genuinely first launch (sentinel absent + no data).
      // The sentinel prevents migration from re-running if Firestore reads
      // temporarily return empty (e.g., a cache miss on offline reopens).
      if (!alreadyMigrated && jobsDocs.isEmpty && entriesDocs.isEmpty && invDocs.isEmpty) {
        await _migrateFromSharedPreferences();
      } else {
        jobs        = jobsDocs.map((d)    => Job.fromJson(d.data())).toList();
        entries     = entriesDocs.map((d) => TimeEntry.fromJson(d.data())).toList();
        invoices    = invDocs.map((d)     => Invoice.fromJson(d.data())).toList();
        expenses    = expDocs.map((d)     => ExpenseItem.fromJson(d.data())).toList();
        activeTimers = timerDocs.map((d)  => ActiveTimer.fromJson(d.data())).toList();
        businesses  = clientDocs.map((d)  => Business.fromJson(d.data())).toList();
        categories  = categoryDocs.map((d) => EntryCategory.fromJson(d.data())).toList();
        if (settingsSnap.exists && settingsSnap.data() != null) {
          settings = AppSettings.fromJson(settingsSnap.data()!);
        }
      }
    } catch (e) {
      debugPrint('AppProvider.load error: $e');
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> reload() async {
    if (_workspaceId == null) return;
    try {
      final results = await Future.wait([
        _col('jobs').get(),
        _col('entries').get(),
        _col('invoices').get(),
        _col('expenses').get(),
        _col('timers').get(),
        _col('businesses').get(),
        _settingsDoc.get(),
        _col('categories').get(),
      ]);
      jobs         = (results[0] as QuerySnapshot<Map<String, dynamic>>).docs.map((d) => Job.fromJson(d.data())).toList();
      entries      = (results[1] as QuerySnapshot<Map<String, dynamic>>).docs.map((d) => TimeEntry.fromJson(d.data())).toList();
      invoices     = (results[2] as QuerySnapshot<Map<String, dynamic>>).docs.map((d) => Invoice.fromJson(d.data())).toList();
      expenses     = (results[3] as QuerySnapshot<Map<String, dynamic>>).docs.map((d) => ExpenseItem.fromJson(d.data())).toList();
      activeTimers = (results[4] as QuerySnapshot<Map<String, dynamic>>).docs.map((d) => ActiveTimer.fromJson(d.data())).toList();
      businesses   = (results[5] as QuerySnapshot<Map<String, dynamic>>).docs.map((d) => Business.fromJson(d.data())).toList();
      categories   = (results[7] as QuerySnapshot<Map<String, dynamic>>).docs.map((d) => EntryCategory.fromJson(d.data())).toList();
      final settingsSnap = results[6] as DocumentSnapshot<Map<String, dynamic>>;
      if (settingsSnap.exists && settingsSnap.data() != null) {
        settings = AppSettings.fromJson(settingsSnap.data()!);
      }
    } catch (e) {
      debugPrint('AppProvider.reload error: $e');
    }
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
      businesses = (jsonDecode(clientsJson) as List)
          .map((e) => Business.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final batch = _db!.batch();
    for (final j in jobs) batch.set(_col('jobs').doc(j.id), j.toJson());
    for (final e in entries) batch.set(_col('entries').doc(e.id), e.toJson());
    for (final i in invoices) batch.set(_col('invoices').doc(i.id), i.toJson());
    for (final e in expenses) batch.set(_col('expenses').doc(e.id), e.toJson());
    for (final t in activeTimers) batch.set(_col('timers').doc(t.id), t.toJson());
    for (final c in businesses) batch.set(_col('businesses').doc(c.id), c.toJson());
    batch.set(_settingsDoc, settings.toJson());
    batch.set(_migrationSentinel, {'migratedAt': DateTime.now().toIso8601String()});
    await batch.commit();
  }

  // ── Jobs ──────────────────────────────────────────────────────────────────

  Future<void> addJob(String name, String description, double? rate, {String? businessId, String? categoryId}) async {
    final job = Job(
      id: _uuid.v4(),
      name: name,
      description: description,
      rate: rate,
      isArchived: false,
      createdAt: DateTime.now(),
      businessId: businessId,
      categoryId: categoryId,
    );
    if (_workspaceId != null) {
      await _col('jobs').doc(job.id).set(job.toJson())
          .timeout(const Duration(seconds: 15));
    }
    jobs = [...jobs, job];
    Analytics.capture('job_created', properties: {
      'has_rate': rate != null,
      'has_description': description.isNotEmpty,
      'has_category': categoryId != null,
    });
    notifyListeners();
  }

  void updateJob(String id, {String? name, String? description, double? rate, bool clearRate = false, String? categoryId, bool clearCategoryId = false, String? businessId, bool clearBusinessId = false}) {
    jobs = jobs.map((j) {
      if (j.id != id) return j;
      return j.copyWith(name: name, description: description, rate: rate, clearRate: clearRate, categoryId: categoryId, clearCategoryId: clearCategoryId, businessId: businessId, clearBusinessId: clearBusinessId);
    }).toList();
    final updated = jobs.firstWhere((j) => j.id == id);
    if (_workspaceId != null) {
      _col('jobs').doc(id).set(updated.toJson());
    }
    Analytics.action('job_updated');
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
    Analytics.capture(updated.isArchived ? 'job_archived' : 'job_unarchived');
    notifyListeners();
  }

  void deleteJob(String id) {
    jobs = jobs.where((j) => j.id != id).toList();
    if (_workspaceId != null) {
      _col('jobs').doc(id).delete();
    }
    Analytics.capture('job_deleted');
    notifyListeners();
  }

  // ── Entries ───────────────────────────────────────────────────────────────

  Future<void> addEntry({
    required String jobId,
    required String date,
    required String startTime,
    required String endTime,
    required double hours,
    required String description,
  }) async {
    final entry = TimeEntry(
      id: _uuid.v4(),
      jobId: jobId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      hours: hours,
      description: description,
    );
    if (_workspaceId != null) {
      await _col('entries').doc(entry.id).set(entry.toJson())
          .timeout(const Duration(seconds: 15));
    }
    entries = [entry, ...entries];
    Analytics.capture('entry_created', properties: {
      'has_job': jobId.isNotEmpty,
      'has_description': description.isNotEmpty,
      'hours': hours,
    });
    notifyListeners();
  }

  void updateEntry(
    String id, {
    String? jobId,
    bool clearJobId = false,
    String? date,
    String? startTime,
    String? endTime,
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
        date: date,
        startTime: startTime,
        endTime: endTime,
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
    Analytics.action('entry_updated');
    notifyListeners();
  }

  Future<({int imported, int skipped, int jobsCreated})> importCsvEntries(
      List<CsvRow> rows) async {
    int imported = 0, skipped = 0, jobsCreated = 0;

    final newJobs    = <Job>[];
    final newEntries = <TimeEntry>[];

    for (final row in rows) {
      Job? job = jobs.where((j) => j.name.toLowerCase() == row.jobName.toLowerCase()).firstOrNull;
      job ??= newJobs.where((j) => j.name.toLowerCase() == row.jobName.toLowerCase()).firstOrNull;

      if (job == null) {
        job = Job(
          id: _uuid.v4(),
          name: row.jobName,
          description: '',
          isArchived: false,
          createdAt: DateTime.now(),
        );
        newJobs.add(job);
        jobsCreated++;
      }

      final isDup = entries.any((e) =>
              e.jobId == job!.id &&
              e.date == row.date &&
              e.startTime == row.startTime &&
              e.endTime == row.endTime &&
              e.description == row.description) ||
          newEntries.any((e) =>
              e.jobId == job!.id &&
              e.date == row.date &&
              e.startTime == row.startTime &&
              e.endTime == row.endTime &&
              e.description == row.description);

      if (isDup) {
        skipped++;
        continue;
      }

      newEntries.add(TimeEntry(
        id: _uuid.v4(),
        jobId: job.id,
        date: row.date,
        startTime: row.startTime,
        endTime: row.endTime,
        hours: row.hours,
        description: row.description,
        rateOverride: row.rate,
      ));
      imported++;
    }

    if (_workspaceId != null && (newJobs.isNotEmpty || newEntries.isNotEmpty)) {
      final ops = <void Function(WriteBatch)>[
        for (final j in newJobs) (b) => b.set(_col('jobs').doc(j.id), j.toJson()),
        for (final e in newEntries) (b) => b.set(_col('entries').doc(e.id), e.toJson()),
      ];
      for (int start = 0; start < ops.length; start += 499) {
        final end = start + 499 < ops.length ? start + 499 : ops.length;
        final batch = _db!.batch();
        for (final op in ops.sublist(start, end)) op(batch);
        await batch.commit();
      }
    }

    jobs = [...jobs, ...newJobs];
    entries = ([...entries, ...newEntries]
          ..sort((a, b) {
            final d = b.date.compareTo(a.date);
            return d != 0 ? d : b.startTime.compareTo(a.startTime);
          }));
    Analytics.action('csv_imported', properties: {
      'imported': imported,
      'skipped': skipped,
      'jobs_created': jobsCreated,
    });
    notifyListeners();

    return (imported: imported, skipped: skipped, jobsCreated: jobsCreated);
  }

  void deleteEntry(String id) {
    entries = entries.where((e) => e.id != id).toList();
    if (_workspaceId != null) {
      _col('entries').doc(id).delete();
    }
    Analytics.capture('entry_deleted');
    notifyListeners();
  }

  void addBreak(String id, int breakMinutes) {
    final idx = entries.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final deducted = (entries[idx].hours - breakMinutes / 60.0).clamp(0.0, double.infinity);
    entries = [...entries];
    entries[idx] = entries[idx].copyWith(hours: deducted);
    if (_workspaceId != null) {
      _col('entries').doc(id).set(entries[idx].toJson());
    }
    Analytics.action('break_added', properties: {'minutes': breakMinutes});
    notifyListeners();
  }

  void addAdjustment(String id, double hoursAdjustment) {
    final idx = entries.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final adjusted = (entries[idx].hours + hoursAdjustment).clamp(0.0, double.infinity);
    entries = [...entries];
    entries[idx] = entries[idx].copyWith(hours: adjusted);
    if (_workspaceId != null) {
      _col('entries').doc(id).set(entries[idx].toJson());
    }
    Analytics.action('adjustment_added', properties: {'hours': hoursAdjustment});
    notifyListeners();
  }

  // ── Invoices ──────────────────────────────────────────────────────────────

  Future<void> createInvoice({
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
  }) async {
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

    Business? newBusiness;
    if (clientCompany != null || clientName != null) {
      final alreadySaved = businesses.any((c) =>
          c.company == (clientCompany?.isEmpty == true ? null : clientCompany) &&
          c.name == (clientName?.isEmpty == true ? null : clientName));
      if (!alreadySaved) {
        newBusiness = Business(
          id: _uuid.v4(),
          name: clientName?.isEmpty == true ? null : clientName,
          company: clientCompany?.isEmpty == true ? null : clientCompany,
          phone: clientPhone?.isEmpty == true ? null : clientPhone,
        );
      }
    }

    final updatedEntries = entries.map((e) {
      if (!entryIds.contains(e.id)) return e;
      return e.copyWith(invoiceId: inv.id);
    }).toList();
    final updatedExpenses = expenses.map((e) {
      if (!expenseIds.contains(e.id)) return e;
      return e.copyWith(invoiceId: inv.id);
    }).toList();

    if (_workspaceId != null) {
      final batch = _db!.batch();
      batch.set(_col('invoices').doc(inv.id), inv.toJson());
      for (final e in updatedEntries.where((e) => entryIds.contains(e.id))) {
        batch.set(_col('entries').doc(e.id), e.toJson());
      }
      for (final e in updatedExpenses.where((e) => expenseIds.contains(e.id))) {
        batch.set(_col('expenses').doc(e.id), e.toJson());
      }
      if (newBusiness != null) {
        batch.set(_col('businesses').doc(newBusiness.id), newBusiness.toJson());
      }
      await batch.commit().timeout(const Duration(seconds: 15));
    }

    invoices = [...invoices, inv];
    if (newBusiness != null) businesses = [...businesses, newBusiness];
    entries = updatedEntries;
    expenses = updatedExpenses;
    Analytics.capture('invoice_created', properties: {
      'entry_count': entryIds.length,
      'expense_count': expenseIds.length,
      'total_hours': totalHours,
      'has_client': clientName != null || clientCompany != null,
    });
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
    Analytics.action('invoice_marked_paid', properties: {'payment_method': paymentMethod});
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
    Analytics.action('invoice_unmarked_paid');
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
    Analytics.capture('invoice_deleted');
    notifyListeners();
  }

  // ── Businesses ────────────────────────────────────────────────────────────

  void addBusiness({String? name, String? company, String? phone}) {
    final business = Business(
        id: _uuid.v4(), name: name, company: company, phone: phone);
    businesses = [...businesses, business];
    if (_workspaceId != null) {
      _col('businesses').doc(business.id).set(business.toJson());
    }
    Analytics.action('business_added');
    notifyListeners();
  }

  void deleteBusiness(String id) {
    businesses = businesses.where((c) => c.id != id).toList();
    if (_workspaceId != null) {
      _col('businesses').doc(id).delete();
    }
    Analytics.action('business_deleted');
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
    Analytics.action('payment_method_added');
    notifyListeners();
  }

  // ── Categories ───────────────────────────────────────────────────────────

  EntryCategory? getCategoryForJob(Job? job) {
    if (job?.categoryId == null) return null;
    return categories.where((c) => c.id == job!.categoryId).firstOrNull;
  }

  Future<void> addCategory(String name, int colorValue) async {
    final cat = EntryCategory(
      id: _uuid.v4(),
      name: name,
      colorValue: colorValue,
      createdAt: DateTime.now().toIso8601String(),
    );
    if (_workspaceId != null) {
      await _col('categories').doc(cat.id).set(cat.toJson())
          .timeout(const Duration(seconds: 15));
    }
    categories = [...categories, cat];
    Analytics.capture('category_created');
    notifyListeners();
  }

  void updateCategory(String id, {String? name, int? colorValue}) {
    categories = categories.map((c) {
      if (c.id != id) return c;
      return c.copyWith(name: name, colorValue: colorValue);
    }).toList();
    final updated = categories.firstWhere((c) => c.id == id);
    if (_workspaceId != null) {
      _col('categories').doc(id).set(updated.toJson());
    }
    Analytics.action('category_updated');
    notifyListeners();
  }

  void deleteCategory(String id) {
    categories = categories.where((c) => c.id != id).toList();
    if (_workspaceId != null) {
      _col('categories').doc(id).delete();
    }
    Analytics.capture('category_deleted');
    notifyListeners();
  }

  // ── Expenses ──────────────────────────────────────────────────────────────

  Future<void> addExpense({
    required String description,
    required double amount,
    required String date,
    required String purchasedBy,
    String? businessId,
    String? jobId,
  }) async {
    final expense = ExpenseItem(
      id: _uuid.v4(),
      description: description,
      amount: amount,
      date: date,
      purchasedBy: purchasedBy,
      businessId: businessId,
      jobId: jobId,
    );
    if (_workspaceId != null) {
      await _col('expenses').doc(expense.id).set(expense.toJson())
          .timeout(const Duration(seconds: 15));
    }
    expenses = [expense, ...expenses];
    Analytics.action('expense_added', properties: {'amount': amount});
    notifyListeners();
  }

  void deleteExpense(String id) {
    expenses = expenses.where((e) => e.id != id).toList();
    if (_workspaceId != null) {
      _col('expenses').doc(id).delete();
    }
    Analytics.action('expense_deleted');
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
    Analytics.action('settings_updated');
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
    Analytics.capture('timer_started', properties: {'has_job': jobId != null});
    notifyListeners();
  }

  Future<void> clockOut(String timerId, {String? jobId, String? description}) async {
    final timer = activeTimers.where((t) => t.id == timerId).firstOrNull;
    if (timer == null) return;

    final now = DateTime.now();
    final totalElapsedSeconds = now.difference(timer.startedAt).inSeconds;
    // Count any active break in progress as additional break time
    final activeBreakSeconds = timer.breakStartedAt != null
        ? now.difference(timer.breakStartedAt!).inSeconds
        : 0;
    final breakSeconds = timer.totalBreakSeconds + activeBreakSeconds;
    final billableSeconds = (totalElapsedSeconds - breakSeconds).clamp(0, totalElapsedSeconds);
    final hours = billableSeconds / 3600.0;

    final today = now.toIso8601String().substring(0, 10);
    final startStr = '${_p2(timer.startedAt.hour)}:${_p2(timer.startedAt.minute)}';
    final endStr = '${_p2(now.hour)}:${_p2(now.minute)}';

    final entry = TimeEntry(
      id: _uuid.v4(),
      jobId: jobId ?? timer.jobId,
      date: today,
      startTime: startStr,
      endTime: endStr,
      hours: hours,
      description: description ?? '',
      rateOverride: timer.rateOverride,
    );

    if (_workspaceId != null) {
      final batch = _db!.batch();
      batch.delete(_col('timers').doc(timerId));
      batch.set(_col('entries').doc(entry.id), entry.toJson());
      await batch.commit().timeout(const Duration(seconds: 15));
    }
    entries = [entry, ...entries];
    activeTimers = activeTimers.where((t) => t.id != timerId).toList();
    Analytics.capture('timer_stopped', properties: {
      'hours': hours,
      'has_description': (description ?? '').isNotEmpty,
    });
    notifyListeners();
  }

  void discardTimer(String timerId) {
    activeTimers = activeTimers.where((t) => t.id != timerId).toList();
    if (_workspaceId != null) {
      _col('timers').doc(timerId).delete();
    }
    Analytics.action('timer_discarded');
    notifyListeners();
  }

  void startBreak(String timerId) {
    final timer = activeTimers.where((t) => t.id == timerId).firstOrNull;
    if (timer == null || timer.isOnBreak) return;
    final updated = timer.copyWith(breakStartedAt: DateTime.now());
    activeTimers = activeTimers.map((t) => t.id == timerId ? updated : t).toList();
    if (_workspaceId != null) {
      _col('timers').doc(timerId).update({'breakStartedAt': updated.breakStartedAt!.toIso8601String()});
    }
    Analytics.action('break_started');
    notifyListeners();
  }

  void endBreak(String timerId) {
    final timer = activeTimers.where((t) => t.id == timerId).firstOrNull;
    if (timer == null || !timer.isOnBreak) return;
    final breakSeconds = DateTime.now().difference(timer.breakStartedAt!).inSeconds;
    final updated = timer.copyWith(
      clearBreakStartedAt: true,
      totalBreakSeconds: timer.totalBreakSeconds + breakSeconds,
    );
    activeTimers = activeTimers.map((t) => t.id == timerId ? updated : t).toList();
    if (_workspaceId != null) {
      _col('timers').doc(timerId).update({
        'breakStartedAt': null,
        'totalBreakSeconds': updated.totalBreakSeconds,
      });
    }
    Analytics.action('break_ended', properties: {'seconds': breakSeconds});
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
