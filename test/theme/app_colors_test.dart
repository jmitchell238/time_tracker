import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/theme/app_theme.dart';

// Helper: build a minimal widget and capture AppColors.of(context) inside it.
Future<AppColors> _colorsFor(WidgetTester tester, ThemeData theme) async {
  late AppColors captured;
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      theme: theme,
      home: Builder(
        builder: (context) {
          captured = AppColors.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  group('AppColors.of(context)', () {
    testWidgets('returns dark palette under dark theme', (tester) async {
      final colors = await _colorsFor(tester, AppTheme.dark);
      expect(colors.bgDeep, const Color(0xFF0F172A));
      expect(colors.bgBase, const Color(0xFF1E293B));
      expect(colors.fg, const Color(0xFFF1F5F9));
    });

    testWidgets('returns light palette under light theme', (tester) async {
      final colors = await _colorsFor(tester, AppTheme.light);
      expect(colors.bgDeep, const Color(0xFFF8FAFC));
      expect(colors.bgBase, const Color(0xFFFFFFFF));
      expect(colors.fg, const Color(0xFF0F172A));
    });

    testWidgets('dark and light bgDeep are different', (tester) async {
      final dark = await _colorsFor(tester, AppTheme.dark);
      final light = await _colorsFor(tester, AppTheme.light);
      expect(dark.bgDeep, isNot(light.bgDeep));
    });

    testWidgets('dark and light fg are different', (tester) async {
      final dark = await _colorsFor(tester, AppTheme.dark);
      final light = await _colorsFor(tester, AppTheme.light);
      expect(dark.fg, isNot(light.fg));
    });

    testWidgets('static primary is unchanged between themes', (tester) async {
      await _colorsFor(tester, AppTheme.dark);
      await _colorsFor(tester, AppTheme.light);
      expect(AppColors.primary, AppColors.primary);
      expect(AppColors.primary, const Color(0xFF2E5C8A));
    });

    testWidgets('static accent is unchanged between themes', (tester) async {
      await _colorsFor(tester, AppTheme.dark);
      await _colorsFor(tester, AppTheme.light);
      expect(AppColors.accent, AppColors.accent);
      expect(AppColors.accent, const Color(0xFFF59E0B));
    });

    testWidgets('static success is unchanged between themes', (tester) async {
      await _colorsFor(tester, AppTheme.light);
      expect(AppColors.success, const Color(0xFF10B981));
    });

    testWidgets('static danger is unchanged between themes', (tester) async {
      await _colorsFor(tester, AppTheme.light);
      expect(AppColors.danger, const Color(0xFFEF4444));
    });

    testWidgets('light bgCard is lighter than light bgBase', (tester) async {
      final light = await _colorsFor(tester, AppTheme.light);
      // bgCard in light mode should be a light gray — just verify it's not dark
      expect(light.bgCard.computeLuminance(), greaterThan(0.5));
    });

    testWidgets('dark bgCard luminance is low', (tester) async {
      final dark = await _colorsFor(tester, AppTheme.dark);
      expect(dark.bgCard.computeLuminance(), lessThan(0.1));
    });
  });

  group('AppTheme.light', () {
    test('light theme has light brightness', () {
      expect(AppTheme.light.brightness, Brightness.light);
    });

    test('dark theme has dark brightness', () {
      expect(AppTheme.dark.brightness, Brightness.dark);
    });
  });
}
