import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_settings.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _rateCtrl;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final rate = context.read<AppProvider>().settings.defaultRate;
    _rateCtrl = TextEditingController(text: rate.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final rate = double.tryParse(_rateCtrl.text.trim());
    if (rate == null) return;
    context.read<AppProvider>().updateSettings(AppSettings(defaultRate: rate));
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  InputDecoration _inputDec() => InputDecoration(
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text('Settings', style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.fg)),
        const SizedBox(height: 20),

        // Default hourly rate
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: Border.all(color: AppColors.border),
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
                    Text('Default Hourly Rate',
                        style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.fg)),
                    const SizedBox(height: 2),
                    Text('Applied to all jobs unless overridden per-job',
                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.fg2)),
                  ],
                ),
              ),
              Container(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Text('\$', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.fg)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _rateCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.dmSans(color: AppColors.fg, fontSize: 13),
                        decoration: _inputDec(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('/ hr', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.fg2)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Users
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Users', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.fg)),
                ),
              ),
              Container(height: 1, color: AppColors.border),
              _userRow('JM', 'James Mitchell', 'james@example.com'),
              Container(height: 1, color: AppColors.borderLight),
              _userRow('SM', 'Sarah Mitchell', 'sarah@example.com'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // App info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text('Property Work Time Tracker', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.fg2), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('Version 1.0 · For James & Sarah Mitchell',
                  style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.fg3), textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Save button
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: Icon(_saved ? Icons.check : Icons.save, size: 18),
            label: Text(_saved ? 'Saved!' : 'Save Changes',
                style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _saved ? AppColors.success : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _userRow(String initials, String name, String email) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Center(
              child: Text(initials, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.fg)),
              Text(email, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.fg2)),
            ],
          ),
        ],
      ),
    );
  }
}
