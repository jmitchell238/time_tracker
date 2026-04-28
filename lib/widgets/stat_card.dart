import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final double hours;
  final double amount;
  final bool accent;
  final bool gold;

  const StatCard({
    super.key,
    required this.label,
    required this.hours,
    required this.amount,
    this.accent = false,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color borderColor;
    Color labelColor;
    Color hoursColor;
    Color amountColor;

    if (accent) {
      bg = AppColors.primary;
      borderColor = AppColors.primary;
      labelColor = Colors.white.withAlpha(165);
      hoursColor = Colors.white;
      amountColor = Colors.white.withAlpha(204);
    } else if (gold) {
      bg = AppColors.accent.withAlpha(20);
      borderColor = AppColors.accent.withAlpha(76);
      labelColor = AppColors.accent;
      hoursColor = AppColors.fg;
      amountColor = AppColors.accent;
    } else {
      bg = AppColors.bgCard;
      borderColor = AppColors.border;
      labelColor = AppColors.fg3;
      hoursColor = AppColors.fg;
      amountColor = AppColors.accent;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
          boxShadow: accent
              ? [BoxShadow(color: AppColors.primary.withAlpha(89), blurRadius: 16, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: labelColor,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${hours.toStringAsFixed(1)}h',
              style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w700, color: hoursColor, height: 1),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}',
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: amountColor),
            ),
          ],
        ),
      ),
    );
  }
}
