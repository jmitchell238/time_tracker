import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/theme/app_theme.dart';
import 'package:time_tracker/widgets/stat_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: Row(children: [child])),
    );

void main() {
  group('StatCard', () {
    testWidgets('renders label uppercased', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(label: 'this week', hours: 8.0, amount: 360.0),
      ));
      expect(find.text('THIS WEEK'), findsOneWidget);
    });

    testWidgets('renders hours with one decimal and h suffix', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(label: 'Week', hours: 8.0, amount: 360.0),
      ));
      expect(find.text('8.0h'), findsOneWidget);
    });

    testWidgets('renders amount with dollar sign and two decimals', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(label: 'Week', hours: 8.0, amount: 360.0),
      ));
      expect(find.text('\$360.00'), findsOneWidget);
    });

    testWidgets('formats large amounts with commas', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(label: 'Week', hours: 0, amount: 1234.56),
      ));
      expect(find.text('\$1,234.56'), findsOneWidget);
    });

    testWidgets('wrapped in Expanded', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(label: 'Week', hours: 8.0, amount: 360.0),
      ));
      expect(find.byType(Expanded), findsOneWidget);
    });

    testWidgets('default mode container background is bgCard', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(label: 'Week', hours: 8.0, amount: 360.0),
      ));
      final container = tester.widget<Container>(
        find.descendant(of: find.byType(StatCard), matching: find.byType(Container)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF334155));
    });

    testWidgets('default mode label text color is fg3', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(label: 'Week', hours: 8.0, amount: 360.0),
      ));
      final labelText = tester.widget<Text>(find.text('WEEK'));
      expect(labelText.style!.color, const Color(0xFF64748B));
    });

    testWidgets('default mode hours text color is fg', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(label: 'Week', hours: 8.0, amount: 360.0),
      ));
      final hoursText = tester.widget<Text>(find.text('8.0h'));
      expect(hoursText.style!.color, const Color(0xFFF1F5F9));
    });

    testWidgets('default mode amount text color is accent', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(label: 'Week', hours: 8.0, amount: 360.0),
      ));
      final amountText = tester.widget<Text>(find.text('\$360.00'));
      expect(amountText.style!.color, AppColors.accent);
    });

    testWidgets('accent mode container background is primary', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(label: 'Week', hours: 8.0, amount: 360.0, accent: true),
      ));
      final container = tester.widget<Container>(
        find.descendant(of: find.byType(StatCard), matching: find.byType(Container)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.primary);
    });

    testWidgets('accent mode hours text color is white', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(label: 'Week', hours: 8.0, amount: 360.0, accent: true),
      ));
      final hoursText = tester.widget<Text>(find.text('8.0h'));
      expect(hoursText.style!.color, Colors.white);
    });

    testWidgets('accent mode has boxShadow', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(label: 'Week', hours: 8.0, amount: 360.0, accent: true),
      ));
      final container = tester.widget<Container>(
        find.descendant(of: find.byType(StatCard), matching: find.byType(Container)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('default mode has no boxShadow', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(label: 'Week', hours: 8.0, amount: 360.0),
      ));
      final container = tester.widget<Container>(
        find.descendant(of: find.byType(StatCard), matching: find.byType(Container)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('gold mode label color is accent', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(label: 'Week', hours: 8.0, amount: 360.0, gold: true),
      ));
      final labelText = tester.widget<Text>(find.text('WEEK'));
      expect(labelText.style!.color, AppColors.accent);
    });

    testWidgets('gold mode hours text color is fg', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatCard(label: 'Week', hours: 8.0, amount: 360.0, gold: true),
      ));
      final hoursText = tester.widget<Text>(find.text('8.0h'));
      expect(hoursText.style!.color, const Color(0xFFF1F5F9));
    });
  });
}
