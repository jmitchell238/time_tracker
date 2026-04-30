import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/theme/app_theme.dart';
import 'package:time_tracker/widgets/amount_display_pair.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('AmountDisplayPair', () {
    testWidgets('renders hours text', (tester) async {
      await tester.pumpWidget(_wrap(const AmountDisplayPair(
        hoursText: '2.5h',
        amountText: r'$112.50',
      )));
      expect(find.text('2.5h'), findsOneWidget);
    });

    testWidgets('renders amount text', (tester) async {
      await tester.pumpWidget(_wrap(const AmountDisplayPair(
        hoursText: '2.5h',
        amountText: r'$112.50',
      )));
      expect(find.text(r'$112.50'), findsOneWidget);
    });

    testWidgets('hours text is bold and AppColors.fg colored', (tester) async {
      await tester.pumpWidget(_wrap(const AmountDisplayPair(
        hoursText: '2.5h',
        amountText: r'$112.50',
      )));
      final hoursText = tester.widget<Text>(find.text('2.5h'));
      expect(hoursText.style!.fontWeight, FontWeight.w700);
      expect(hoursText.style!.color, AppColors.fg);
    });

    testWidgets('amount color defaults to AppColors.fg2', (tester) async {
      await tester.pumpWidget(_wrap(const AmountDisplayPair(
        hoursText: '2.5h',
        amountText: r'$112.50',
      )));
      final amountText = tester.widget<Text>(find.text(r'$112.50'));
      expect(amountText.style!.color, AppColors.fg2);
    });

    testWidgets('amount color can be overridden', (tester) async {
      await tester.pumpWidget(_wrap(AmountDisplayPair(
        hoursText: '2.5h',
        amountText: r'$112.50',
        amountColor: AppColors.accent,
      )));
      final amountText = tester.widget<Text>(find.text(r'$112.50'));
      expect(amountText.style!.color, AppColors.accent);
    });

    testWidgets('hours font size defaults to 13', (tester) async {
      await tester.pumpWidget(_wrap(const AmountDisplayPair(
        hoursText: '2.5h',
        amountText: r'$112.50',
      )));
      final hoursText = tester.widget<Text>(find.text('2.5h'));
      expect(hoursText.style!.fontSize, 13);
    });

    testWidgets('hours font size can be overridden to 12', (tester) async {
      await tester.pumpWidget(_wrap(const AmountDisplayPair(
        hoursText: '2.5h',
        amountText: r'$112.50',
        hoursSize: 12,
      )));
      final hoursText = tester.widget<Text>(find.text('2.5h'));
      expect(hoursText.style!.fontSize, 12);
    });

    testWidgets('amount font size is always 11', (tester) async {
      await tester.pumpWidget(_wrap(const AmountDisplayPair(
        hoursText: '2.5h',
        amountText: r'$112.50',
      )));
      final amountText = tester.widget<Text>(find.text(r'$112.50'));
      expect(amountText.style!.fontSize, 11);
    });

    testWidgets('column is end-aligned', (tester) async {
      await tester.pumpWidget(_wrap(const AmountDisplayPair(
        hoursText: '2.5h',
        amountText: r'$112.50',
      )));
      final column = tester.widget<Column>(find.byType(Column).last);
      expect(column.crossAxisAlignment, CrossAxisAlignment.end);
    });

    testWidgets('renders comma-formatted amount', (tester) async {
      await tester.pumpWidget(_wrap(const AmountDisplayPair(
        hoursText: '100.0h',
        amountText: r'$1,234.56',
      )));
      expect(find.text(r'$1,234.56'), findsOneWidget);
    });
  });
}
