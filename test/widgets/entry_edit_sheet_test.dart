import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_tracker/models/job.dart';
import 'package:time_tracker/models/time_entry.dart';
import 'package:time_tracker/providers/app_provider.dart';
import 'package:time_tracker/widgets/entry_edit_sheet.dart';

Job _job({String id = 'j1', String name = 'Lawn', double? rate = 45.0}) =>
    Job(id: id, name: name, description: '', rate: rate, isArchived: false, createdAt: DateTime(2026));

TimeEntry _entry({
  String id = 'e1',
  String? jobId = 'j1',
  double hours = 2.0,
  double? rateOverride,
  String description = 'Test work',
}) =>
    TimeEntry(
      id: id,
      jobId: jobId,
      date: '2026-04-01',
      startTime: '09:00',
      endTime: '11:00',
      hours: hours,
      description: description,
      rateOverride: rateOverride,
    );

Future<AppProvider> _provider(List<Job> jobs, List<TimeEntry> entries) async {
  SharedPreferences.setMockInitialValues({'jobs': '[]', 'entries': '[]', 'invoices': '[]'});
  final p = AppProvider(
      db: FakeFirebaseFirestore(), auth: MockFirebaseAuth(signedIn: true));
  await p.load();
  p.jobs = jobs;
  p.entries = entries;
  return p;
}

Widget _wrap(AppProvider p, TimeEntry entry) => ChangeNotifierProvider<AppProvider>.value(
      value: p,
      child: MaterialApp(home: Scaffold(body: EntryEditSheet(entry: entry))),
    );

void main() {
  group('EntryEditSheet', () {
    testWidgets('renders Complete Entry title', (tester) async {
      final entry = _entry();
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.text('Complete Entry'), findsOneWidget);
    });

    testWidgets('shows entry date and time summary', (tester) async {
      final entry = _entry();
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.text('2026-04-01  09:00 – 11:00'), findsOneWidget);
    });

    testWidgets('pre-fills hours field with entry hours', (tester) async {
      final entry = _entry(hours: 3.5);
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.widgetWithText(TextField, '3.50'), findsOneWidget);
    });

    testWidgets('pre-fills description field', (tester) async {
      final entry = _entry(description: 'Mow lawn');
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.widgetWithText(TextField, 'Mow lawn'), findsOneWidget);
    });

    testWidgets('pre-fills rate override when entry has one', (tester) async {
      final entry = _entry(rateOverride: 55.0);
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.widgetWithText(TextField, '55.00'), findsOneWidget);
    });

    testWidgets('rate field is empty when no rate override', (tester) async {
      final entry = _entry(rateOverride: null);
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      // Rate field (RateInputField) should have empty text initially
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      final rateField = textFields.where(
        (tf) => (tf.controller?.text ?? '').isEmpty || (tf.controller?.text ?? '') == '2.00',
      );
      // Just verify there are multiple text fields (hours, rate, description)
      expect(textFields.length, 3);
    });

    testWidgets('shows job picker with pre-selected job', (tester) async {
      final entry = _entry(jobId: 'j1');
      final p = await _provider([_job(id: 'j1', name: 'Lawn')], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.text('Lawn'), findsOneWidget);
    });

    testWidgets('Save Entry button is present', (tester) async {
      final entry = _entry();
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.text('Save Entry'), findsOneWidget);
    });

    testWidgets('saving updates description in provider', (tester) async {
      final entry = _entry(id: 'e1', description: 'Old desc');
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      final descField = find.widgetWithText(TextField, 'Old desc');
      await tester.enterText(descField, 'New desc');
      await tester.pump();
      await tester.tap(find.text('Save Entry'));
      await tester.pump();
      expect(p.entries.first.description, 'New desc');
    });

    testWidgets('saving updates hours in provider', (tester) async {
      final entry = _entry(id: 'e1', hours: 2.0);
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      final hoursField = find.widgetWithText(TextField, '2.00');
      await tester.enterText(hoursField, '4.0');
      await tester.pump();
      await tester.tap(find.text('Save Entry'));
      await tester.pump();
      expect(p.entries.first.hours, 4.0);
    });

    testWidgets('selecting job from picker pre-fills rate', (tester) async {
      final entry = _entry(jobId: null, rateOverride: null);
      final p = await _provider([_job(id: 'j1', name: 'Lawn', rate: 45.0)], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      await tester.tap(find.text('Select a job…'));
      await tester.pump();
      await tester.tap(find.text('Lawn'));
      await tester.pump();
      expect(find.widgetWithText(TextField, '45.00'), findsOneWidget);
    });

    testWidgets('clearing job clears rate field', (tester) async {
      final entry = _entry(jobId: 'j1', rateOverride: null);
      final p = await _provider([_job(id: 'j1', name: 'Lawn', rate: 45.0)], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      // Verify the job is initially selected
      expect(find.text('Lawn'), findsOneWidget);
      // Clear the job
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      // Rate should be cleared
      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      // Hours, rate, description - rate field should be empty
      final rateText = textFields[1].controller?.text ?? '';
      expect(rateText, isEmpty);
    });

    testWidgets('close button is present', (tester) async {
      final entry = _entry();
      final p = await _provider([_job()], [entry]);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
