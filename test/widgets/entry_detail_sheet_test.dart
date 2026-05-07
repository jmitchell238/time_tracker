import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_tracker/models/job.dart';
import 'package:time_tracker/models/time_entry.dart';
import 'package:time_tracker/providers/app_provider.dart';
import 'package:time_tracker/widgets/entry_detail_sheet.dart';

Job _job({String id = 'j1', String name = 'Lawn', double? rate = 45.0}) =>
    Job(id: id, name: name, description: '', rate: rate, isArchived: false, createdAt: DateTime(2026));

TimeEntry _entry({
  String id = 'e1',
  String? jobId = 'j1',
  double hours = 2.0,
  String description = '',
}) =>
    TimeEntry(
      id: id,
      jobId: jobId,
      date: '2026-04-01',
      startTime: '09:00',
      endTime: '11:00',
      hours: hours,
      description: description,
    );

Future<AppProvider> _provider(List<Job> jobs, List<TimeEntry> entries) async {
  SharedPreferences.setMockInitialValues({'jobs': '[]', 'entries': '[]', 'invoices': '[]'});
  final p = AppProvider(db: FakeFirebaseFirestore(), auth: MockFirebaseAuth(signedIn: true));
  await p.load();
  p.jobs = jobs;
  p.entries = entries;
  return p;
}

Widget _wrap(AppProvider p, TimeEntry entry) => ChangeNotifierProvider<AppProvider>.value(
      value: p,
      child: MaterialApp(home: Scaffold(body: EntryDetailSheet(entry: entry))),
    );

void main() {
  group('EntryDetailSheet', () {
    testWidgets('renders Entry Details title', (tester) async {
      final entry = _entry();
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.text('Entry Details'), findsOneWidget);
    });

    testWidgets('shows formatted date', (tester) async {
      final entry = _entry();
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.text('Apr 1, 2026'), findsOneWidget);
    });

    testWidgets('shows time range for time-based entries', (tester) async {
      final entry = _entry();
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.textContaining('9:00 AM'), findsOneWidget);
      expect(find.textContaining('11:00 AM'), findsOneWidget);
    });

    testWidgets('shows hours', (tester) async {
      final entry = _entry(hours: 2.0);
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.textContaining('2.00 hrs'), findsOneWidget);
    });

    testWidgets('shows job name', (tester) async {
      final entry = _entry(jobId: 'j1');
      final p = await _provider([_job(id: 'j1', name: 'Lawn')], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.text('Lawn'), findsOneWidget);
    });

    testWidgets('shows earnings', (tester) async {
      final entry = _entry(hours: 2.0);
      final p = await _provider([_job(rate: 45.0)], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.textContaining('\$90.00'), findsOneWidget);
    });

    testWidgets('shows notes when description is present', (tester) async {
      final entry = _entry(description: 'Mowed the lawn');
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.text('Mowed the lawn'), findsOneWidget);
    });

    testWidgets('shows Edit Entry button', (tester) async {
      final entry = _entry();
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.text('Edit Entry'), findsOneWidget);
    });

    testWidgets('shows Add Break button', (tester) async {
      final entry = _entry();
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.text('Add Break'), findsOneWidget);
    });

    testWidgets('shows Add Adjustment button', (tester) async {
      final entry = _entry();
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.text('Add Adjustment'), findsOneWidget);
    });

    testWidgets('has close button', (tester) async {
      final entry = _entry();
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
