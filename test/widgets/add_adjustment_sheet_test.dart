import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_tracker/models/job.dart';
import 'package:time_tracker/models/time_entry.dart';
import 'package:time_tracker/providers/app_provider.dart';
import 'package:time_tracker/widgets/add_adjustment_sheet.dart';

Job _job() =>
    Job(id: 'j1', name: 'Lawn', description: '', rate: 45.0, isArchived: false, createdAt: DateTime(2026));

TimeEntry _entry({double hours = 2.0}) => TimeEntry(
      id: 'e1',
      jobId: 'j1',
      date: '2026-04-01',
      startTime: '09:00',
      endTime: '11:00',
      hours: hours,
      description: '',
    );

Future<AppProvider> _provider(TimeEntry entry) async {
  SharedPreferences.setMockInitialValues({'jobs': '[]', 'entries': '[]', 'invoices': '[]'});
  final p = AppProvider(db: FakeFirebaseFirestore(), auth: MockFirebaseAuth(signedIn: true));
  await p.load();
  p.jobs = [_job()];
  p.entries = [entry];
  return p;
}

Widget _wrap(AppProvider p, TimeEntry entry) => ChangeNotifierProvider<AppProvider>.value(
      value: p,
      child: MaterialApp(home: Scaffold(body: AddAdjustmentSheet(entry: entry))),
    );

void main() {
  group('AddAdjustmentSheet', () {
    testWidgets('renders Add Adjustment title', (tester) async {
      final entry = _entry();
      final p = await _provider(entry);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.text('Add Adjustment'), findsOneWidget);
    });

    testWidgets('shows hours input field', (tester) async {
      final entry = _entry();
      final p = await _provider(entry);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows current entry duration', (tester) async {
      final entry = _entry(hours: 2.0);
      final p = await _provider(entry);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.textContaining('2.00'), findsWidgets);
    });

    testWidgets('has Add and Subtract toggle buttons', (tester) async {
      final entry = _entry();
      final p = await _provider(entry);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Subtract'), findsOneWidget);
    });

    testWidgets('has Apply Adjustment button', (tester) async {
      final entry = _entry();
      final p = await _provider(entry);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.text('Apply Adjustment'), findsOneWidget);
    });

    testWidgets('Apply Adjustment adds hours when Add selected', (tester) async {
      final entry = _entry(hours: 2.0);
      final p = await _provider(entry);
      await tester.pumpWidget(_wrap(p, entry));
      await tester.enterText(find.byType(TextField), '0.5');
      await tester.pump();
      await tester.tap(find.text('Apply Adjustment'));
      await tester.pump();
      expect(p.entries.first.hours, closeTo(2.5, 0.001));
    });

    testWidgets('Apply Adjustment subtracts hours when Subtract selected', (tester) async {
      final entry = _entry(hours: 2.0);
      final p = await _provider(entry);
      await tester.pumpWidget(_wrap(p, entry));
      await tester.tap(find.text('Subtract'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '0.5');
      await tester.pump();
      await tester.tap(find.text('Apply Adjustment'));
      await tester.pump();
      expect(p.entries.first.hours, closeTo(1.5, 0.001));
    });

    testWidgets('empty input does not change hours', (tester) async {
      final entry = _entry(hours: 2.0);
      final p = await _provider(entry);
      await tester.pumpWidget(_wrap(p, entry));
      await tester.tap(find.text('Apply Adjustment'));
      await tester.pump();
      expect(p.entries.first.hours, 2.0);
    });

    testWidgets('has close button', (tester) async {
      final entry = _entry();
      final p = await _provider(entry);
      await tester.pumpWidget(_wrap(p, entry));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
