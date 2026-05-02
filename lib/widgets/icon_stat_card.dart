import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class IconStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const IconStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.of(context).bgCard,
        border: Border.all(color: AppColors.of(context).border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.accent),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.lora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.of(context).fg,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.of(context).fg3),
          ),
        ],
      ),
    );
  }
}
