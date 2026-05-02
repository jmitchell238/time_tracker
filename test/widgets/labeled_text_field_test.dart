import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/widgets/labeled_text_field.dart';
import 'package:time_tracker/theme/app_theme.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(theme: AppTheme.dark, home: Scaffold(body: child));

  group('LabeledTextField', () {
    testWidgets('renders a TextField', (tester) async {
      await tester.pumpWidget(wrap(
        LabeledTextField(
          label: 'Name',
          controller: TextEditingController(),
        ),
      ));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('label text appears in decoration', (tester) async {
      await tester.pumpWidget(wrap(
        LabeledTextField(
          label: 'Client Name',
          controller: TextEditingController(),
        ),
      ));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.decoration?.labelText, 'Client Name');
    });

    testWidgets('fill color is const Color(0xFF334155)', (tester) async {
      await tester.pumpWidget(wrap(
        LabeledTextField(
          label: 'Name',
          controller: TextEditingController(),
        ),
      ));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.decoration?.fillColor, const Color(0xFF334155));
      expect(tf.decoration?.filled, isTrue);
    });

    testWidgets('default keyboardType is text', (tester) async {
      await tester.pumpWidget(wrap(
        LabeledTextField(
          label: 'Name',
          controller: TextEditingController(),
        ),
      ));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.keyboardType, TextInputType.text);
    });

    testWidgets('custom keyboardType is applied', (tester) async {
      await tester.pumpWidget(wrap(
        LabeledTextField(
          label: 'Phone',
          controller: TextEditingController(),
          keyboardType: TextInputType.phone,
        ),
      ));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.keyboardType, TextInputType.phone);
    });

    testWidgets('controller is wired to the TextField', (tester) async {
      final ctrl = TextEditingController(text: 'hello');
      await tester.pumpWidget(wrap(
        LabeledTextField(label: 'Name', controller: ctrl),
      ));
      expect(find.text('hello'), findsOneWidget);
    });
  });
}
