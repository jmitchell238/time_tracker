import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/theme/app_theme.dart';
import 'package:time_tracker/widgets/date_picker_button.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('DatePickerButton', () {
    testWidgets('renders the provided label text', (tester) async {
      await tester.pumpWidget(_wrap(DatePickerButton(
        label: 'Apr 30',
        onTap: () {},
      )));
      expect(find.text('Apr 30'), findsOneWidget);
    });

    testWidgets('renders calendar icon', (tester) async {
      await tester.pumpWidget(_wrap(DatePickerButton(
        label: 'Apr 30',
        onTap: () {},
      )));
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(DatePickerButton(
        label: 'Apr 30',
        onTap: () => tapped = true,
      )));
      await tester.tap(find.byType(DatePickerButton));
      expect(tapped, isTrue);
    });

    testWidgets('label text color is AppColors.fg', (tester) async {
      await tester.pumpWidget(_wrap(DatePickerButton(
        label: 'Apr 30',
        onTap: () {},
      )));
      final text = tester.widget<Text>(find.text('Apr 30'));
      expect(text.style!.color, AppColors.fg);
    });

    testWidgets('icon color is AppColors.fg2', (tester) async {
      await tester.pumpWidget(_wrap(DatePickerButton(
        label: 'Apr 30',
        onTap: () {},
      )));
      final icon = tester.widget<Icon>(find.byIcon(Icons.calendar_today_outlined));
      expect(icon.color, AppColors.fg2);
    });

    testWidgets('container has bgElevated background', (tester) async {
      await tester.pumpWidget(_wrap(DatePickerButton(
        label: 'Apr 30',
        onTap: () {},
      )));
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, AppColors.bgElevated);
    });

    testWidgets('container has height 44', (tester) async {
      await tester.pumpWidget(_wrap(DatePickerButton(
        label: 'Apr 30',
        onTap: () {},
      )));
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.minHeight, 44);
    });
  });
}
