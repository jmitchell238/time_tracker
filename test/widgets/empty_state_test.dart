import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/theme/app_theme.dart';
import 'package:time_tracker/widgets/empty_state.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('EmptyStateWidget', () {
    testWidgets('renders the message text', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyStateWidget('No items found')));
      expect(find.text('No items found'), findsOneWidget);
    });

    testWidgets('text is centered', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyStateWidget('No items found')));
      final text = tester.widget<Text>(find.text('No items found'));
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets('text color is AppColors.fg3', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyStateWidget('No items found')));
      final text = tester.widget<Text>(find.text('No items found'));
      expect(text.style!.color, AppColors.fg3);
    });

    testWidgets('text font size is 13', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyStateWidget('No items found')));
      final text = tester.widget<Text>(find.text('No items found'));
      expect(text.style!.fontSize, 13);
    });

    testWidgets('wrapped in Padding with vertical 32 by default', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyStateWidget('No items found')));
      final padding = tester.widget<Padding>(
        find.ancestor(
            of: find.text('No items found'), matching: find.byType(Padding)),
      );
      final insets = padding.padding as EdgeInsets;
      expect(insets.top, 32);
      expect(insets.bottom, 32);
    });

    testWidgets('uses custom verticalPadding when provided', (tester) async {
      await tester.pumpWidget(
          _wrap(const EmptyStateWidget('No items found', verticalPadding: 24)));
      final padding = tester.widget<Padding>(
        find.ancestor(
            of: find.text('No items found'), matching: find.byType(Padding)),
      );
      final insets = padding.padding as EdgeInsets;
      expect(insets.top, 24);
      expect(insets.bottom, 24);
    });
  });
}
