import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class RateInputField extends StatelessWidget {
  final TextEditingController controller;
  final double? jobDefaultRate;

  const RateInputField({
    super.key,
    required this.controller,
    this.jobDefaultRate,
  });

  InputDecoration _inputDec() => InputDecoration(
        hintText: '0.00',
        filled: true,
        fillColor: AppColors.bgElevated,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: GoogleFonts.dmSans(color: AppColors.fg3, fontSize: 13),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              child: Text(
                r'$',
                style: GoogleFonts.dmSans(color: AppColors.fg2, fontSize: 16),
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.dmSans(color: AppColors.fg, fontSize: 13),
                decoration: _inputDec(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '/hr',
                style: GoogleFonts.dmSans(color: AppColors.fg2, fontSize: 13),
              ),
            ),
          ],
        ),
        if (jobDefaultRate != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Job default: \$${jobDefaultRate!.toStringAsFixed(2)}/hr',
              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.fg3),
            ),
          ),
      ],
    );
  }
}
