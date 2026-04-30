import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/widgets/metric_item.dart';
import 'package:time_tracker/theme/app_theme.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('MetricItem', () {
    testWidgets('renders label uppercased', (tester) async {
      await tester.pumpWidget(wrap(
        const MetricItem(label: 'hours', value: '8.0'),
      ));
      expect(find.text('HOURS'), findsOneWidget);
    });

    testWidgets('renders value text', (tester) async {
      await tester.pumpWidget(wrap(
        const MetricItem(label: 'Hours', value: '8.0'),
      ));
      expect(find.text('8.0'), findsOneWidget);
    });

    testWidgets('value text defaults to AppColors.fg', (tester) async {
      await tester.pumpWidget(wrap(
        const MetricItem(label: 'Hours', value: '8.0'),
      ));
      final valueText = tester.widget<Text>(find.text('8.0'));
      expect(valueText.style?.color, AppColors.fg);
    });

    testWidgets('label text uses AppColors.fg2', (tester) async {
      await tester.pumpWidget(wrap(
        const MetricItem(label: 'Hours', value: '8.0'),
      ));
      final labelText = tester.widget<Text>(find.text('HOURS'));
      expect(labelText.style?.color, AppColors.fg2);
    });

    testWidgets('custom color applies to value text', (tester) async {
      await tester.pumpWidget(wrap(
        MetricItem(label: 'Earnings', value: r'$100.00', color: AppColors.accent),
      ));
      final valueText = tester.widget<Text>(find.text(r'$100.00'));
      expect(valueText.style?.color, AppColors.accent);
    });

    testWidgets('column is crossAxisAlignment start', (tester) async {
      await tester.pumpWidget(wrap(
        const MetricItem(label: 'Hours', value: '8.0'),
      ));
      final col = tester.widget<Column>(
        find.byWidgetPredicate((w) =>
            w is Column &&
            w.crossAxisAlignment == CrossAxisAlignment.start),
      );
      expect(col, isNotNull);
    });
  });
}
