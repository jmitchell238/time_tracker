import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final double verticalPadding;
  const EmptyStateWidget(this.message, {super.key, this.verticalPadding = 32});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.fg3),
      ),
    );
  }
}
