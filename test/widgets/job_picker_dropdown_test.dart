import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/models/job.dart';
import 'package:time_tracker/theme/app_theme.dart';
import 'package:time_tracker/widgets/job_picker_dropdown.dart';

Job _job(String id, String name) => Job(
      id: id,
      name: name,
      description: '',
      isArchived: false,
      createdAt: DateTime(2024),
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  final jobs = [_job('j1', 'Web Design'), _job('j2', 'iOS Dev')];

  group('JobPickerDropdown', () {
    testWidgets('shows placeholder when no job selected', (tester) async {
      await tester.pumpWidget(_wrap(JobPickerDropdown(
        jobs: jobs,
        selectedJobId: null,
        onJobSelected: (_) {},
        placeholder: 'Pick a job…',
      )));
      expect(find.text('Pick a job…'), findsOneWidget);
    });

    testWidgets('shows selected job name when job is selected', (tester) async {
      await tester.pumpWidget(_wrap(JobPickerDropdown(
        jobs: jobs,
        selectedJobId: 'j1',
        onJobSelected: (_) {},
      )));
      expect(find.text('Web Design'), findsOneWidget);
    });

    testWidgets('tapping trigger opens the dropdown (search field appears)', (tester) async {
      await tester.pumpWidget(_wrap(JobPickerDropdown(
        jobs: jobs,
        selectedJobId: null,
        onJobSelected: (_) {},
      )));
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('Select a job…'));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('tapping trigger again closes the dropdown', (tester) async {
      await tester.pumpWidget(_wrap(JobPickerDropdown(
        jobs: jobs,
        selectedJobId: null,
        onJobSelected: (_) {},
      )));
      await tester.tap(find.text('Select a job…'));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.text('Select a job…'));
      await tester.pump();
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('tapping a job calls onJobSelected with that job id', (tester) async {
      String? selected;
      await tester.pumpWidget(_wrap(JobPickerDropdown(
        jobs: jobs,
        selectedJobId: null,
        onJobSelected: (id) => selected = id,
      )));
      await tester.tap(find.text('Select a job…'));
      await tester.pump();
      await tester.tap(find.text('iOS Dev'));
      await tester.pump();
      expect(selected, 'j2');
    });

    testWidgets('tapping a job closes the dropdown', (tester) async {
      await tester.pumpWidget(_wrap(JobPickerDropdown(
        jobs: jobs,
        selectedJobId: null,
        onJobSelected: (_) {},
      )));
      await tester.tap(find.text('Select a job…'));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.text('iOS Dev'));
      await tester.pump();
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('clear button shown when allowDeselect=true and job selected', (tester) async {
      await tester.pumpWidget(_wrap(JobPickerDropdown(
        jobs: jobs,
        selectedJobId: 'j1',
        onJobSelected: (_) {},
        allowDeselect: true,
      )));
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('clear button hidden when allowDeselect=false', (tester) async {
      await tester.pumpWidget(_wrap(JobPickerDropdown(
        jobs: jobs,
        selectedJobId: 'j1',
        onJobSelected: (_) {},
        allowDeselect: false,
      )));
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('tapping clear calls onJobSelected(null)', (tester) async {
      String? received = 'initial';
      await tester.pumpWidget(_wrap(JobPickerDropdown(
        jobs: jobs,
        selectedJobId: 'j1',
        onJobSelected: (id) => received = id,
        allowDeselect: true,
      )));
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(received, isNull);
    });

    testWidgets('search text filters visible jobs', (tester) async {
      await tester.pumpWidget(_wrap(JobPickerDropdown(
        jobs: jobs,
        selectedJobId: null,
        onJobSelected: (_) {},
      )));
      await tester.tap(find.text('Select a job…'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'web');
      await tester.pump();
      expect(find.text('Web Design'), findsOneWidget);
      expect(find.text('iOS Dev'), findsNothing);
    });

    testWidgets('Add new job row shown when onAddJob provided', (tester) async {
      await tester.pumpWidget(_wrap(JobPickerDropdown(
        jobs: jobs,
        selectedJobId: null,
        onJobSelected: (_) {},
        onAddJob: () async {},
      )));
      await tester.tap(find.text('Select a job…'));
      await tester.pump();
      expect(find.text('Add new job…'), findsOneWidget);
    });

    testWidgets('Add new job row hidden when onAddJob is null', (tester) async {
      await tester.pumpWidget(_wrap(JobPickerDropdown(
        jobs: jobs,
        selectedJobId: null,
        onJobSelected: (_) {},
      )));
      await tester.tap(find.text('Select a job…'));
      await tester.pump();
      expect(find.text('Add new job…'), findsNothing);
    });

    testWidgets('selected job row uses primary color text', (tester) async {
      await tester.pumpWidget(_wrap(JobPickerDropdown(
        jobs: jobs,
        selectedJobId: 'j1',
        onJobSelected: (_) {},
      )));
      await tester.tap(find.text('Web Design'));
      await tester.pump();
      final texts = tester.widgetList<Text>(find.text('Web Design'));
      final listText = texts.firstWhere(
        (t) => (t.style?.color) == AppColors.primary,
        orElse: () => texts.first,
      );
      expect(listText.style?.color, AppColors.primary);
    });
  });
}
