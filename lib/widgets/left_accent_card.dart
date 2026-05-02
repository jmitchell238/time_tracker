import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LeftAccentCard extends StatelessWidget {
  final Color accentColor;
  final Widget child;
  final EdgeInsets contentPadding;
  final double borderRadius;
  final Color? outerBorderColor;

  const LeftAccentCard({
    super.key,
    required this.accentColor,
    required this.child,
    this.contentPadding = const EdgeInsets.fromLTRB(8, 10, 12, 10),
    this.borderRadius = 10,
    this.outerBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.of(context).bgCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: outerBorderColor ?? AppColors.of(context).border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(color: accentColor),
            ),
            Expanded(
              child: Padding(
                padding: contentPadding,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
