import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class DatePickerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const DatePickerButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(label,
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.fg)),
            const Spacer(),
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.fg2, size: 16),
          ],
        ),
      ),
    );
  }
}
