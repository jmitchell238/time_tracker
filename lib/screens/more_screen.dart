import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import 'categories_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text('More',
            style: GoogleFonts.lora(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
        const SizedBox(height: 20),
        _NavTile(
          icon: Icons.bar_chart_outlined,
          label: 'Insights',
          onTap: () {
            Analytics.action('insights_opened');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _PushedScreen(title: 'Insights', child: InsightsScreen())),
            );
          },
        ),
        const SizedBox(height: 8),
        _NavTile(
          icon: Icons.label_outlined,
          label: 'Categories',
          onTap: () {
            Analytics.action('categories_opened');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            );
          },
        ),
        const SizedBox(height: 8),
        _NavTile(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: () {
            Analytics.action('settings_opened');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _PushedScreen(title: 'Settings', child: SettingsScreen())),
            );
          },
        ),
      ],
    );
  }
}

class _PushedScreen extends StatelessWidget {
  final String title;
  final Widget child;

  const _PushedScreen({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).bgDeep,
      body: Column(
        children: [
          Container(
            color: AppColors.of(context).bgDeep,
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 12,
              16,
              12,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, size: 18, color: AppColors.of(context).fg),
                      const SizedBox(width: 4),
                      Text('Back',
                          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.of(context).fg)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.of(context).bgBase,
          border: Border.all(color: AppColors.of(context).border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.of(context).fg2),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.of(context).fg)),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.of(context).fg3),
          ],
        ),
      ),
    );
  }
}
