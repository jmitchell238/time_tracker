import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/theme/app_theme.dart';
import 'package:time_tracker/widgets/left_accent_card.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('LeftAccentCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(_wrap(LeftAccentCard(
        accentColor: AppColors.accent,
        child: const Text('entry content'),
      )));
      expect(find.text('entry content'), findsOneWidget);
    });

    testWidgets('renders 4px left accent strip with given color', (tester) async {
      await tester.pumpWidget(_wrap(LeftAccentCard(
        accentColor: AppColors.primary,
        child: const Text('content'),
      )));
      final containers = tester.widgetList<Container>(find.byType(Container));
      final strip = containers.firstWhere(
        (c) => c.constraints?.maxWidth == 4 || c.constraints?.minWidth == 4,
        orElse: () => containers.firstWhere(
          (c) => (c.decoration as BoxDecoration?)?.color == AppColors.primary,
        ),
      );
      final decoration = strip.decoration as BoxDecoration?;
      expect(decoration?.color ?? strip.color, AppColors.primary);
    });

    testWidgets('outer container has bgCard background', (tester) async {
      await tester.pumpWidget(_wrap(LeftAccentCard(
        accentColor: AppColors.accent,
        child: const Text('content'),
      )));
      final containers = tester.widgetList<Container>(find.byType(Container));
      final outer = containers.first;
      final decoration = outer.decoration as BoxDecoration?;
      expect(decoration?.color, AppColors.bgCard);
    });

    testWidgets('outer container uses default border radius 10', (tester) async {
      await tester.pumpWidget(_wrap(LeftAccentCard(
        accentColor: AppColors.accent,
        child: const Text('content'),
      )));
      final containers = tester.widgetList<Container>(find.byType(Container));
      final outer = containers.first;
      final decoration = outer.decoration as BoxDecoration?;
      expect(decoration?.borderRadius, BorderRadius.circular(10));
    });

    testWidgets('border radius can be overridden to 12', (tester) async {
      await tester.pumpWidget(_wrap(LeftAccentCard(
        accentColor: AppColors.accent,
        borderRadius: 12,
        child: const Text('content'),
      )));
      final containers = tester.widgetList<Container>(find.byType(Container));
      final outer = containers.first;
      final decoration = outer.decoration as BoxDecoration?;
      expect(decoration?.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('contains IntrinsicHeight widget', (tester) async {
      await tester.pumpWidget(_wrap(LeftAccentCard(
        accentColor: AppColors.accent,
        child: const Text('content'),
      )));
      expect(find.byType(IntrinsicHeight), findsOneWidget);
    });

    testWidgets('has clip antiAlias behavior', (tester) async {
      await tester.pumpWidget(_wrap(LeftAccentCard(
        accentColor: AppColors.accent,
        child: const Text('content'),
      )));
      final containers = tester.widgetList<Container>(find.byType(Container));
      final outer = containers.first;
      expect(outer.clipBehavior, Clip.antiAlias);
    });
  });
}
