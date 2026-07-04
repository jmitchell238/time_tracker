import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/analytics_service.dart';
import '../services/app_update.dart';
import '../theme/app_theme.dart';

/// Slim tappable banner shown when a newer build has been downloaded and is
/// waiting to take over. Tapping activates it and reloads the app, showing
/// an "Updating…" state while the reload is in flight.
class UpdateBanner extends StatefulWidget {
  const UpdateBanner({super.key});

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: updateReady,
      builder: (context, ready, _) {
        if (!ready) return const SizedBox.shrink();
        return GestureDetector(
          onTap: _updating
              ? null
              : () {
                  Analytics.action('update_banner_tapped');
                  setState(() => _updating = true);
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
                    if (_updating)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    else
                      const Icon(Icons.refresh, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _updating ? 'Updating…' : 'New version available — tap to update',
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
