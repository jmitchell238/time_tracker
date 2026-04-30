import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/theme/app_theme.dart';
import 'package:time_tracker/widgets/rate_input_field.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('RateInputField', () {
    testWidgets('renders dollar sign prefix', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(_wrap(RateInputField(controller: ctrl)));
      expect(find.text(r'$'), findsOneWidget);
    });

    testWidgets('renders /hr suffix', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(_wrap(RateInputField(controller: ctrl)));
      expect(find.text('/hr'), findsOneWidget);
    });

    testWidgets('contains a TextField', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(_wrap(RateInputField(controller: ctrl)));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('TextField uses provided controller', (tester) async {
      final ctrl = TextEditingController(text: '45.00');
      await tester.pumpWidget(_wrap(RateInputField(controller: ctrl)));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller, ctrl);
    });

    testWidgets('TextField has numeric keyboard type', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(_wrap(RateInputField(controller: ctrl)));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.keyboardType,
          const TextInputType.numberWithOptions(decimal: true));
    });

    testWidgets('no job default hint shown when jobDefaultRate is null',
        (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(_wrap(RateInputField(controller: ctrl)));
      expect(find.textContaining('Job default:'), findsNothing);
    });

    testWidgets('shows job default hint when jobDefaultRate is provided',
        (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(
          _wrap(RateInputField(controller: ctrl, jobDefaultRate: 50.0)));
      expect(find.textContaining('Job default: \$50.00/hr'), findsOneWidget);
    });

    testWidgets('job default hint color is AppColors.fg3', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(
          _wrap(RateInputField(controller: ctrl, jobDefaultRate: 40.0)));
      final hint = tester.widget<Text>(
          find.textContaining('Job default:'));
      expect(hint.style!.color, AppColors.fg3);
    });

    testWidgets('dollar sign color is AppColors.fg2', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(_wrap(RateInputField(controller: ctrl)));
      final dollar = tester.widget<Text>(find.text(r'$'));
      expect(dollar.style!.color, AppColors.fg2);
    });

    testWidgets('/hr color is AppColors.fg2', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(_wrap(RateInputField(controller: ctrl)));
      final hr = tester.widget<Text>(find.text('/hr'));
      expect(hr.style!.color, AppColors.fg2);
    });
  });
}
