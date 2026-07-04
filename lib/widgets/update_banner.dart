import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/analytics_service.dart';
import '../services/app_update.dart';
import '../theme/app_theme.dart';

/// Slim tappable banner shown when a newer build has been downloaded and is
/// waiting to take over. Tapping activates it and reloads the app.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: updateReady,
      builder: (context, ready, _) {
        if (!ready) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () {
            Analytics.action('update_banner_tapped');
            applyUpdate();
          },
          child: Container(
            width: double.infinity,
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'New version available — tap to update',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
