import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SegmentedToggleBar extends StatelessWidget {
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;
  final double height;

  const SegmentedToggleBar({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.height = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: height),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: labels.map((label) {
          final isActive = label == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(label),
              child: Container(
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.fg2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
