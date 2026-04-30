import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/widgets/segmented_toggle_bar.dart';
import 'package:time_tracker/theme/app_theme.dart';

void main() {
  Widget wrap({
    required List<String> labels,
    required String selected,
    required ValueChanged<String> onChanged,
    double height = 38,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SegmentedToggleBar(
          labels: labels,
          selected: selected,
          onChanged: onChanged,
          height: height,
        ),
      ),
    );
  }

  group('SegmentedToggleBar', () {
    testWidgets('renders all labels', (tester) async {
      await tester.pumpWidget(wrap(
        labels: const ['Active', 'Archived'],
        selected: 'Active',
        onChanged: (_) {},
      ));
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
    });

    testWidgets('renders four labels', (tester) async {
      await tester.pumpWidget(wrap(
        labels: const ['Day', 'Week', 'Month', 'Job'],
        selected: 'Day',
        onChanged: (_) {},
      ));
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Job'), findsOneWidget);
    });

    testWidgets('active segment has primary color background', (tester) async {
      await tester.pumpWidget(wrap(
        labels: const ['Active', 'Archived'],
        selected: 'Active',
        onChanged: (_) {},
      ));
      final activeContainers = find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == AppColors.primary);
      expect(activeContainers, findsOneWidget);
    });

    testWidgets('inactive segment has transparent background', (tester) async {
      await tester.pumpWidget(wrap(
        labels: const ['Active', 'Archived'],
        selected: 'Active',
        onChanged: (_) {},
      ));
      final inactiveContainers = find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == Colors.transparent);
      expect(inactiveContainers, findsOneWidget);
    });

    testWidgets('tapping an inactive segment calls onChanged with its label',
        (tester) async {
      String? tapped;
      await tester.pumpWidget(wrap(
        labels: const ['Active', 'Archived'],
        selected: 'Active',
        onChanged: (v) => tapped = v,
      ));
      await tester.tap(find.text('Archived'));
      expect(tapped, 'Archived');
    });

    testWidgets('tapping the active segment still calls onChanged', (tester) async {
      String? tapped;
      await tester.pumpWidget(wrap(
        labels: const ['Active', 'Archived'],
        selected: 'Active',
        onChanged: (v) => tapped = v,
      ));
      await tester.tap(find.text('Active'));
      expect(tapped, 'Active');
    });

    testWidgets('active label text is white', (tester) async {
      await tester.pumpWidget(wrap(
        labels: const ['Active', 'Archived'],
        selected: 'Active',
        onChanged: (_) {},
      ));
      final activeText = tester.widget<Text>(find.text('Active'));
      expect(activeText.style?.color, Colors.white);
    });

    testWidgets('inactive label text is fg2 color', (tester) async {
      await tester.pumpWidget(wrap(
        labels: const ['Active', 'Archived'],
        selected: 'Active',
        onChanged: (_) {},
      ));
      final inactiveText = tester.widget<Text>(find.text('Archived'));
      expect(inactiveText.style?.color, AppColors.fg2);
    });

    testWidgets('custom height is applied to outer container', (tester) async {
      await tester.pumpWidget(wrap(
        labels: const ['A', 'B'],
        selected: 'A',
        onChanged: (_) {},
        height: 50,
      ));
      final outerContainer = tester.widget<Container>(
        find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == AppColors.bgCard),
      );
      final sizedBox = outerContainer.constraints;
      expect(sizedBox?.maxHeight, 50);
    });

    testWidgets('selected can be changed to second item', (tester) async {
      await tester.pumpWidget(wrap(
        labels: const ['Active', 'Archived'],
        selected: 'Archived',
        onChanged: (_) {},
      ));
      final activeContainers = find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == AppColors.primary);
      // Only 'Archived' should be primary-colored
      expect(activeContainers, findsOneWidget);
      final activeText = tester.widget<Text>(find.text('Archived'));
      expect(activeText.style?.color, Colors.white);
    });
  });
}
