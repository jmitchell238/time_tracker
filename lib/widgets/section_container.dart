import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SectionContainer extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const SectionContainer({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).bgCard,
        border: Border.all(color: AppColors.of(context).border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.of(context).fg),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style:
                        GoogleFonts.dmSans(fontSize: 11, color: AppColors.of(context).fg2),
                  ),
                ],
              ],
            ),
          ),
          Container(height: 1, color: AppColors.of(context).border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}
