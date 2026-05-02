import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const MetricItem({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.of(context).fg2,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color ?? AppColors.of(context).fg,
          ),
        ),
      ],
    );
  }
}
