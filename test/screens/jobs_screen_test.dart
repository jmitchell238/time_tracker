import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_tracker/providers/app_provider.dart';
import 'package:time_tracker/screens/jobs_screen.dart';
import 'package:time_tracker/widgets/segmented_toggle_bar.dart';

Future<AppProvider> _emptyProvider() async {
  SharedPreferences.setMockInitialValues(
      {'jobs': '[]', 'entries': '[]', 'invoices': '[]'});
  final p = AppProvider(
      db: FakeFirebaseFirestore(), auth: MockFirebaseAuth(signedIn: true));
  await p.load();
  return p;
}

Future<AppProvider> _defaultProvider() async {
  SharedPreferences.setMockInitialValues({});
  final p = AppProvider(
      db: FakeFirebaseFirestore(), auth: MockFirebaseAuth(signedIn: true));
  await p.load();
  return p;
}

Widget _wrap(AppProvider provider) => ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: const MaterialApp(home: Scaffold(body: JobsScreen())),
    );

void main() {
  group('JobsScreen', () {
    testWidgets('renders Jobs header', (tester) async {
      final p = await _emptyProvider();
      await tester.pumpWidget(_wrap(p));
      expect(find.text('Jobs'), findsOneWidget);
    });

    testWidgets('renders Add Job button', (tester) async {
      final p = await _emptyProvider();
      await tester.pumpWidget(_wrap(p));
      expect(find.text('Add Job'), findsOneWidget);
    });

    testWidgets('renders SegmentedToggleBar with Active and Archived labels',
        (tester) async {
      final p = await _emptyProvider();
      await tester.pumpWidget(_wrap(p));
      expect(find.byType(SegmentedToggleBar), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
    });

    testWidgets('shows empty-active message when no active jobs', (tester) async {
      final p = await _emptyProvider();
      await tester.pumpWidget(_wrap(p));
      expect(find.text('No active jobs'), findsOneWidget);
    });

    testWidgets('renders active job names from default data', (tester) async {
      final p = await _defaultProvider();
      await tester.pumpWidget(_wrap(p));
      expect(find.text('Wedding Venue Golf Cart'), findsOneWidget);
    });

    testWidgets('renders hours for a job card', (tester) async {
      final p = await _emptyProvider();
      p.addJob('Test Job', '', null);
      await tester.pumpWidget(_wrap(p));
      await tester.pump();
      // no entries → 0.0 hours
      expect(find.text('0.0h'), findsOneWidget);
    });

    testWidgets('switching to Archived tab shows archived job from default data',
        (tester) async {
      final p = await _defaultProvider();
      await tester.pumpWidget(_wrap(p));
      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();
      expect(find.text('Spray for Ants'), findsOneWidget);
    });

    testWidgets('switching to Archived tab shows empty message when none archived',
        (tester) async {
      final p = await _emptyProvider();
      await tester.pumpWidget(_wrap(p));
      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();
      expect(find.text('No archived jobs'), findsOneWidget);
    });

    testWidgets('tapping Add Job opens dialog', (tester) async {
      final p = await _emptyProvider();
      await tester.pumpWidget(_wrap(p));
      await tester.tap(find.text('Add Job'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('dialog cancel dismisses without adding job', (tester) async {
      final p = await _emptyProvider();
      await tester.pumpWidget(_wrap(p));
      await tester.tap(find.text('Add Job'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(p.jobs, isEmpty);
    });

    testWidgets('dialog Add with empty name does not add job', (tester) async {
      final p = await _emptyProvider();
      await tester.pumpWidget(_wrap(p));
      await tester.tap(find.text('Add Job'));
      await tester.pumpAndSettle();
      // tap Add without entering a name
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(p.jobs, isEmpty);
    });

    testWidgets('dialog Add with valid name adds job and dismisses',
        (tester) async {
      final p = await _emptyProvider();
      await tester.pumpWidget(_wrap(p));
      await tester.tap(find.text('Add Job'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'New Test Job');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('New Test Job'), findsOneWidget);
    });

    testWidgets('job card shows description when non-empty', (tester) async {
      final p = await _emptyProvider();
      p.addJob('Test Job', 'A description', null);
      await tester.pumpWidget(_wrap(p));
      await tester.pump();
      expect(find.text('A description'), findsOneWidget);
    });

    testWidgets('job card shows rate override when rate is set', (tester) async {
      final p = await _defaultProvider();
      await tester.pumpWidget(_wrap(p));
      // 'Little Motorcycle' has rate: 40
      expect(find.text('\$40/hr override'), findsOneWidget);
    });

    // Active timer card
    testWidgets('active timer card is not shown when no timers are running',
        (tester) async {
      final p = await _emptyProvider();
      await tester.pumpWidget(_wrap(p));
      expect(find.text('CLOCKED IN'), findsNothing);
    });

    testWidgets('active timer card is shown when a timer is running',
        (tester) async {
      final p = await _emptyProvider();
      p.clockIn();
      await tester.pumpWidget(_wrap(p));
      await tester.pump();
      expect(find.text('CLOCKED IN'), findsOneWidget);
    });

    testWidgets('active timer card shows job name when timer has a job',
        (tester) async {
      final p = await _emptyProvider();
      p.addJob('Test Job', '', null);
      final jobId = p.jobs.first.id;
      p.clockIn(jobId: jobId);
      await tester.pumpWidget(_wrap(p));
      await tester.pump();
      expect(find.text('Test Job'), findsWidgets);
    });

    testWidgets('active timer card shows Clock Out button', (tester) async {
      final p = await _emptyProvider();
      p.clockIn();
      await tester.pumpWidget(_wrap(p));
      await tester.pump();
      expect(find.text('Clock Out'), findsOneWidget);
    });

    testWidgets('active timer card shows Start Break button when not on break',
        (tester) async {
      final p = await _emptyProvider();
      p.clockIn();
      await tester.pumpWidget(_wrap(p));
      await tester.pump();
      expect(find.text('Start Break'), findsOneWidget);
    });

    testWidgets(
        'active timer card shows ON BREAK and End Break when on break',
        (tester) async {
      final p = await _emptyProvider();
      p.clockIn();
      await tester.pump();
      final timerId = p.activeTimers.first.id;
      p.startBreak(timerId);
      await tester.pumpWidget(_wrap(p));
      await tester.pump();
      expect(find.text('ON BREAK'), findsOneWidget);
      expect(find.text('End Break'), findsOneWidget);
    });

    testWidgets('tapping Start Break calls startBreak on provider',
        (tester) async {
      final p = await _emptyProvider();
      p.clockIn();
      await tester.pumpWidget(_wrap(p));
      await tester.pump();
      await tester.tap(find.text('Start Break'));
      await tester.pump();
      expect(p.activeTimers.first.isOnBreak, true);
    });

    testWidgets('tapping End Break calls endBreak on provider', (tester) async {
      final p = await _emptyProvider();
      p.clockIn();
      await tester.pump();
      final timerId = p.activeTimers.first.id;
      p.startBreak(timerId);
      await tester.pumpWidget(_wrap(p));
      await tester.pump();
      await tester.tap(find.text('End Break'));
      await tester.pump();
      expect(p.activeTimers.first.isOnBreak, false);
    });

    testWidgets('tapping Clock Out removes the active timer', (tester) async {
      final p = await _emptyProvider();
      p.clockIn();
      await tester.pumpWidget(_wrap(p));
      await tester.pump();
      await tester.tap(find.text('Clock Out'));
      await tester.pump();
      expect(p.activeTimers, isEmpty);
    });
  });
}
