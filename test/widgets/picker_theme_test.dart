import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/theme/app_theme.dart';

void main() {
  Future<ThemeData> pickerThemeUnder(WidgetTester tester, ThemeData appTheme) async {
    late ThemeData result;
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        darkTheme: appTheme,
        home: Builder(
          builder: (context) {
            result = AppTheme.picker(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('picker theme is light with readable text in light mode', (tester) async {
    final t = await pickerThemeUnder(tester, AppTheme.light);
    expect(t.brightness, Brightness.light);
    expect(t.colorScheme.primary, AppColors.accent);
    // Text must be dark on the light surface.
    expect(t.colorScheme.onSurface.computeLuminance(), lessThan(0.5));
    expect(t.colorScheme.surface.computeLuminance(), greaterThan(0.5));
  });

  testWidgets('picker theme is dark with readable text in dark mode', (tester) async {
    final t = await pickerThemeUnder(tester, AppTheme.dark);
    expect(t.brightness, Brightness.dark);
    expect(t.colorScheme.primary, AppColors.accent);
    expect(t.colorScheme.onSurface.computeLuminance(), greaterThan(0.5));
    expect(t.colorScheme.surface.computeLuminance(), lessThan(0.5));
  });
}
