import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/widgets/field_label.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('FieldLabel', () {
    testWidgets('renders text uppercased', (tester) async {
      await tester.pumpWidget(wrap(const FieldLabel('job name')));
      expect(find.text('JOB NAME'), findsOneWidget);
    });

    testWidgets('already-uppercase text renders correctly', (tester) async {
      await tester.pumpWidget(wrap(const FieldLabel('RATE')));
      expect(find.text('RATE'), findsOneWidget);
    });

    testWidgets('has bottom padding', (tester) async {
      await tester.pumpWidget(wrap(const FieldLabel('test')));
      final padding = tester.widget<Padding>(find.byType(Padding).first);
      expect(padding.padding, const EdgeInsets.only(bottom: 6));
    });

    testWidgets('text style uses correct font size and letter spacing',
        (tester) async {
      await tester.pumpWidget(wrap(const FieldLabel('label')));
      final text = tester.widget<Text>(find.text('LABEL'));
      expect(text.style?.fontSize, 11);
      expect(text.style?.letterSpacing, 0.6);
    });
  });
}
