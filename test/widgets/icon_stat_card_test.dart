import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/widgets/icon_stat_card.dart';
import 'package:time_tracker/theme/app_theme.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(theme: AppTheme.dark, home: Scaffold(body: child));

  group('IconStatCard', () {
    testWidgets('renders value text', (tester) async {
      await tester.pumpWidget(wrap(
        const IconStatCard(label: 'Hours', value: '8.0', icon: Icons.access_time_outlined),
      ));
      expect(find.text('8.0'), findsOneWidget);
    });

    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(wrap(
        const IconStatCard(label: 'Hours', value: '8.0', icon: Icons.access_time_outlined),
      ));
      expect(find.text('Hours'), findsOneWidget);
    });

    testWidgets('renders the icon', (tester) async {
      await tester.pumpWidget(wrap(
        const IconStatCard(label: 'Hours', value: '8.0', icon: Icons.access_time_outlined),
      ));
      expect(find.byIcon(Icons.access_time_outlined), findsOneWidget);
    });

    testWidgets('icon color is AppColors.accent', (tester) async {
      await tester.pumpWidget(wrap(
        const IconStatCard(label: 'Hours', value: '8.0', icon: Icons.access_time_outlined),
      ));
      final icon = tester.widget<Icon>(find.byIcon(Icons.access_time_outlined));
      expect(icon.color, AppColors.accent);
    });

    testWidgets('container has bgCard background', (tester) async {
      await tester.pumpWidget(wrap(
        const IconStatCard(label: 'Hours', value: '8.0', icon: Icons.access_time_outlined),
      ));
      final container = find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == const Color(0xFF334155));
      expect(container, findsOneWidget);
    });

    testWidgets('label text color is const Color(0xFF64748B)', (tester) async {
      await tester.pumpWidget(wrap(
        const IconStatCard(label: 'Hours', value: '8.0', icon: Icons.access_time_outlined),
      ));
      final labelText = tester.widget<Text>(find.text('Hours'));
      expect(labelText.style?.color, const Color(0xFF64748B));
    });

    testWidgets('value text color is const Color(0xFFF1F5F9)', (tester) async {
      await tester.pumpWidget(wrap(
        const IconStatCard(label: 'Hours', value: '8.0', icon: Icons.access_time_outlined),
      ));
      final valueText = tester.widget<Text>(find.text('8.0'));
      expect(valueText.style?.color, const Color(0xFFF1F5F9));
    });
  });
}
