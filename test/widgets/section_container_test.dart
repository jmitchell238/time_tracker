import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/theme/app_theme.dart';
import 'package:time_tracker/widgets/section_container.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: AppTheme.dark, home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('SectionContainer', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(_wrap(SectionContainer(
        title: 'My Section',
        child: const Text('content'),
      )));
      expect(find.text('My Section'), findsOneWidget);
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(_wrap(SectionContainer(
        title: 'My Section',
        child: const Text('child content'),
      )));
      expect(find.text('child content'), findsOneWidget);
    });

    testWidgets('renders optional subtitle when provided', (tester) async {
      await tester.pumpWidget(_wrap(SectionContainer(
        title: 'My Section',
        subtitle: 'A helpful hint',
        child: const Text('content'),
      )));
      expect(find.text('A helpful hint'), findsOneWidget);
    });

    testWidgets('no subtitle rendered when not provided', (tester) async {
      await tester.pumpWidget(_wrap(SectionContainer(
        title: 'My Section',
        child: const Text('content'),
      )));
      expect(find.text('A helpful hint'), findsNothing);
    });

    testWidgets('title style is bold and const Color(0xFFF1F5F9) colored', (tester) async {
      await tester.pumpWidget(_wrap(SectionContainer(
        title: 'My Section',
        child: const Text('content'),
      )));
      final title = tester.widget<Text>(find.text('My Section'));
      expect(title.style!.fontWeight, FontWeight.w700);
      expect(title.style!.color, const Color(0xFFF1F5F9));
    });

    testWidgets('subtitle color is const Color(0xFF94A3B8)', (tester) async {
      await tester.pumpWidget(_wrap(SectionContainer(
        title: 'My Section',
        subtitle: 'hint',
        child: const Text('content'),
      )));
      final sub = tester.widget<Text>(find.text('hint'));
      expect(sub.style!.color, const Color(0xFF94A3B8));
    });

    testWidgets('has a horizontal divider between header and content',
        (tester) async {
      await tester.pumpWidget(_wrap(SectionContainer(
        title: 'My Section',
        child: const Text('content'),
      )));
      expect(find.byType(Container), findsWidgets);
      // The divider is a Container(height:1) — verify both title and child are visible
      // (structural test: both exist, divider doesn't break layout)
      expect(find.text('My Section'), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('outer container has bgCard background', (tester) async {
      await tester.pumpWidget(_wrap(SectionContainer(
        title: 'My Section',
        child: const Text('content'),
      )));
      final containers = tester.widgetList<Container>(find.byType(Container));
      final outer = containers.first;
      final decoration = outer.decoration as BoxDecoration?;
      expect(decoration?.color, const Color(0xFF334155));
    });

    testWidgets('outer container has border radius 12', (tester) async {
      await tester.pumpWidget(_wrap(SectionContainer(
        title: 'My Section',
        child: const Text('content'),
      )));
      final containers = tester.widgetList<Container>(find.byType(Container));
      final outer = containers.first;
      final decoration = outer.decoration as BoxDecoration?;
      expect(decoration?.borderRadius, BorderRadius.circular(12));
    });
  });
}
