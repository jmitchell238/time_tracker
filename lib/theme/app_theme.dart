import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  final Color bgDeep;
  final Color bgBase;
  final Color bgCard;
  final Color bgElevated;
  final Color fg;
  final Color fg2;
  final Color fg3;
  final Color border;
  final Color borderLight;

  static const Color primary = Color(0xFF2E5C8A);
  static const Color primaryHover = Color(0xFF1E3F5A);
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentDim = Color(0xFFD97706);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);

  const AppColors._({
    required this.bgDeep,
    required this.bgBase,
    required this.bgCard,
    required this.bgElevated,
    required this.fg,
    required this.fg2,
    required this.fg3,
    required this.border,
    required this.borderLight,
  });

  static const AppColors _dark = AppColors._(
    bgDeep: Color(0xFF0F172A),
    bgBase: Color(0xFF1E293B),
    bgCard: Color(0xFF334155),
    bgElevated: Color(0xFF3D4F69),
    fg: Color(0xFFF1F5F9),
    fg2: Color(0xFF94A3B8),
    fg3: Color(0xFF64748B),
    border: Color(0xFF475569),
    borderLight: Color(0xFF334155),
  );

  static const AppColors _light = AppColors._(
    bgDeep: Color(0xFFF8FAFC),
    bgBase: Color(0xFFFFFFFF),
    bgCard: Color(0xFFF1F5F9),
    bgElevated: Color(0xFFE2E8F0),
    fg: Color(0xFF0F172A),
    fg2: Color(0xFF475569),
    fg3: Color(0xFF94A3B8),
    border: Color(0xFFCBD5E1),
    borderLight: Color(0xFFE2E8F0),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}

class AppTheme {
  /// Theme for date/time picker dialogs: follows the ambient brightness and
  /// uses the accent color for the selected day/time.
  static ThemeData picker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? dark : light;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        surface: AppColors.of(context).bgCard,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color fg, Color fg2, Color fg3) {
    return TextTheme(
      displayLarge: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.w700, color: fg),
      displayMedium: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: fg),
      displaySmall: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: fg),
      headlineMedium: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w700, color: fg),
      titleLarge: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: fg),
      titleMedium: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: fg),
      titleSmall: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      bodyLarge: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w400, color: fg),
      bodyMedium: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: fg),
      bodySmall: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w400, color: fg2),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: fg3,
        letterSpacing: 0.06 * 10,
      ),
    );
  }

  static ThemeData get dark {
    const c = AppColors._dark;
    final textTheme = _buildTextTheme(c.fg, c.fg2, c.fg3);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: c.bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Color(0xFF1E293B),
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: c.bgBase,
        foregroundColor: c.fg,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.bgCard,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: c.fg3,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        labelStyle: GoogleFonts.dmSans(color: c.fg2, fontSize: 11),
        hintStyle: GoogleFonts.dmSans(color: c.fg3, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.border),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.bgBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get light {
    const c = AppColors._light;
    final textTheme = _buildTextTheme(c.fg, c.fg2, c.fg3);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: c.bgDeep,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Color(0xFFFFFFFF),
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: c.bgBase,
        foregroundColor: c.fg,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.bgCard,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: c.fg3,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        labelStyle: GoogleFonts.dmSans(color: c.fg2, fontSize: 11),
        hintStyle: GoogleFonts.dmSans(color: c.fg3, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.border),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.bgBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
