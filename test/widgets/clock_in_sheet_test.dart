import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_tracker/models/job.dart';
import 'package:time_tracker/providers/app_provider.dart';
import 'package:time_tracker/widgets/clock_in_sheet.dart';

Job _job({String id = 'j1', String name = 'Lawn', double? rate = 45.0}) =>
    Job(id: id, name: name, description: '', rate: rate, isArchived: false, createdAt: DateTime(2026));

Future<AppProvider> _provider(List<Job> jobs) async {
  SharedPreferences.setMockInitialValues({'jobs': '[]', 'entries': '[]', 'invoices': '[]'});
  final p = AppProvider();
  await p.load();
  p.jobs = jobs;
  return p;
}

Widget _wrap(AppProvider p) => ChangeNotifierProvider<AppProvider>.value(
      value: p,
      child: const MaterialApp(home: Scaffold(body: ClockInSheet())),
    );

void main() {
  group('ClockInSheet', () {
    testWidgets('renders Clock In title and button', (tester) async {
      final p = await _provider([]);
      await tester.pumpWidget(_wrap(p));
      expect(find.text('Clock In'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders hint text about adding details later', (tester) async {
      final p = await _provider([]);
      await tester.pumpWidget(_wrap(p));
      expect(find.text('You can add job & rate details after clocking out'), findsOneWidget);
    });

    testWidgets('shows Clock In button (ElevatedButton) with no job selected', (tester) async {
      final p = await _provider([]);
      await tester.pumpWidget(_wrap(p));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows Clock In — JobName when job is selected', (tester) async {
      final p = await _provider([_job(name: 'Lawn')]);
      await tester.pumpWidget(_wrap(p));
      await tester.tap(find.text('No job — add details later'));
      await tester.pump();
      await tester.tap(find.text('Lawn'));
      await tester.pump();
      expect(find.text('Clock In — Lawn'), findsOneWidget);
    });

    testWidgets('pre-fills rate when job with rate is selected', (tester) async {
      final p = await _provider([_job(name: 'Lawn', rate: 45.0)]);
      await tester.pumpWidget(_wrap(p));
      await tester.tap(find.text('No job — add details later'));
      await tester.pump();
      await tester.tap(find.text('Lawn'));
      await tester.pump();
      expect(find.widgetWithText(TextField, '45.00'), findsOneWidget);
    });

    testWidgets('clears rate when job is deselected', (tester) async {
      final p = await _provider([_job(name: 'Lawn', rate: 45.0)]);
      await tester.pumpWidget(_wrap(p));
      await tester.tap(find.text('No job — add details later'));
      await tester.pump();
      await tester.tap(find.text('Lawn'));
      await tester.pump();
      expect(find.widgetWithText(TextField, '45.00'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.controller?.text ?? '', isEmpty);
    });

    testWidgets('does not pre-fill rate when job has no rate', (tester) async {
      final p = await _provider([_job(name: 'Lawn', rate: null)]);
      await tester.pumpWidget(_wrap(p));
      await tester.tap(find.text('No job — add details later'));
      await tester.pump();
      await tester.tap(find.text('Lawn'));
      await tester.pump();
      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.controller?.text ?? '', isEmpty);
    });

    testWidgets('tapping Clock In calls provider.clockIn with no job', (tester) async {
      final p = await _provider([]);
      await tester.pumpWidget(_wrap(p));
      expect(p.activeTimers, isEmpty);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(p.activeTimers.length, 1);
      expect(p.activeTimers.first.jobId, isNull);
    });

    testWidgets('tapping Clock In calls provider.clockIn with selected job', (tester) async {
      final p = await _provider([_job(id: 'j1', name: 'Lawn', rate: 45.0)]);
      await tester.pumpWidget(_wrap(p));
      await tester.tap(find.text('No job — add details later'));
      await tester.pump();
      await tester.tap(find.text('Lawn'));
      await tester.pump();
      await tester.tap(find.text('Clock In — Lawn'));
      await tester.pump();
      expect(p.activeTimers.length, 1);
      expect(p.activeTimers.first.jobId, 'j1');
    });

    testWidgets('tapping Clock In with rate sets rateOverride on timer', (tester) async {
      final p = await _provider([_job(name: 'Lawn', rate: 45.0)]);
      await tester.pumpWidget(_wrap(p));
      await tester.tap(find.text('No job — add details later'));
      await tester.pump();
      await tester.tap(find.text('Lawn'));
      await tester.pump();
      await tester.tap(find.text('Clock In — Lawn'));
      await tester.pump();
      expect(p.activeTimers.first.rateOverride, 45.0);
    });

    testWidgets('shows job default rate hint when job with rate is selected', (tester) async {
      final p = await _provider([_job(name: 'Lawn', rate: 45.0)]);
      await tester.pumpWidget(_wrap(p));
      await tester.tap(find.text('No job — add details later'));
      await tester.pump();
      await tester.tap(find.text('Lawn'));
      await tester.pump();
      expect(find.text('Job default: \$45.00/hr'), findsOneWidget);
    });

    testWidgets('job picker uses placeholder No job — add details later', (tester) async {
      final p = await _provider([_job()]);
      await tester.pumpWidget(_wrap(p));
      expect(find.text('No job — add details later'), findsOneWidget);
    });

    testWidgets('close button is present', (tester) async {
      final p = await _provider([]);
      await tester.pumpWidget(_wrap(p));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
