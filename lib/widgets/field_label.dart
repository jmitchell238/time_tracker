import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class FieldLabel extends StatelessWidget {
  final String text;

  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.fg2,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
