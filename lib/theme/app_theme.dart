import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bgDeep = Color(0xFF0F172A);
  static const bgBase = Color(0xFF1E293B);
  static const bgCard = Color(0xFF334155);
  static const bgElevated = Color(0xFF3D4F69);
  static const fg = Color(0xFFF1F5F9);
  static const fg2 = Color(0xFF94A3B8);
  static const fg3 = Color(0xFF64748B);
  static const border = Color(0xFF475569);
  static const borderLight = Color(0xFF334155);
  static const primary = Color(0xFF2E5C8A);
  static const primaryHover = Color(0xFF1E3F5A);
  static const accent = Color(0xFFF59E0B);
  static const accentDim = Color(0xFFD97706);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
}

class AppTheme {
  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.lora(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.fg,
      ),
      displayMedium: GoogleFonts.lora(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.fg,
      ),
      displaySmall: GoogleFonts.lora(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.fg,
      ),
      headlineMedium: GoogleFonts.lora(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.fg,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.fg,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.fg,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.fg,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.fg,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.fg,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.fg2,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.fg3,
        letterSpacing: 0.06 * 10,
      ),
    );
  }

  static ThemeData get dark {
    final textTheme = _buildTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.bgBase,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgBase,
        foregroundColor: AppColors.fg,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.fg3,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        labelStyle: GoogleFonts.dmSans(color: AppColors.fg2, fontSize: 11),
        hintStyle: GoogleFonts.dmSans(color: AppColors.fg3, fontSize: 13),
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
        color: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
