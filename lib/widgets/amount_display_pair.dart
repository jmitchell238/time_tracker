import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AmountDisplayPair extends StatelessWidget {
  final String hoursText;
  final String amountText;
  final double hoursSize;
  final Color? amountColor;

  const AmountDisplayPair({
    super.key,
    required this.hoursText,
    required this.amountText,
    this.hoursSize = 13,
    this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          hoursText,
          style: GoogleFonts.dmSans(
            fontSize: hoursSize,
            fontWeight: FontWeight.w700,
            color: AppColors.of(context).fg,
          ),
        ),
        Text(
          amountText,
          style: GoogleFonts.dmSans(fontSize: 11, color: amountColor ?? AppColors.of(context).fg2),
        ),
      ],
    );
  }
}
