import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/section_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _rateCtrl;
  late TextEditingController _billingNameCtrl;
  late TextEditingController _billingAddressCtrl;
  late TextEditingController _billingPhoneCtrl;
  bool _saved = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    final s = context.read<AppProvider>().settings;
    _rateCtrl = TextEditingController(text: s.defaultRate.toStringAsFixed(2));
    _billingNameCtrl = TextEditingController(text: s.billingName ?? '');
    _billingAddressCtrl = TextEditingController(text: s.billingAddress ?? '');
    _billingPhoneCtrl = TextEditingController(text: s.billingPhone ?? '');
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    _billingNameCtrl.dispose();
    _billingAddressCtrl.dispose();
    _billingPhoneCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final rate = double.tryParse(_rateCtrl.text.trim());
    if (rate == null) return;
    final s = context.read<AppProvider>().settings;
    context.read<AppProvider>().updateSettings(s.copyWith(
      defaultRate: rate,
      billingName: _billingNameCtrl.text.trim().isEmpty ? null : _billingNameCtrl.text.trim(),
      clearBillingName: _billingNameCtrl.text.trim().isEmpty,
      billingAddress: _billingAddressCtrl.text.trim().isEmpty ? null : _billingAddressCtrl.text.trim(),
      clearBillingAddress: _billingAddressCtrl.text.trim().isEmpty,
      billingPhone: _billingPhoneCtrl.text.trim().isEmpty ? null : _billingPhoneCtrl.text.trim(),
      clearBillingPhone: _billingPhoneCtrl.text.trim().isEmpty,
    ));
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
        SectionContainer(
          title: 'Default Hourly Rate',
          subtitle: 'Applied to all jobs unless overridden per-job',
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
              _userRow('JM', 'James Mitchell', 'jmitchell238@gmail.com'),
              Container(height: 1, color: AppColors.borderLight),
              _userRow('WM', 'Whitney Mitchell', 'wlmitchell238@gmail.com'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Billing profile
        SectionContainer(
          title: 'Your Billing Info',
          subtitle: 'Appears on PDF invoices as the service provider',
          child: Column(
            children: [
              LabeledTextField(label: 'Name', controller: _billingNameCtrl, keyboardType: TextInputType.name),
              const SizedBox(height: 10),
              LabeledTextField(label: 'Address', controller: _billingAddressCtrl, keyboardType: TextInputType.streetAddress),
              const SizedBox(height: 10),
              LabeledTextField(label: 'Phone', controller: _billingPhoneCtrl, keyboardType: TextInputType.phone),
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
              Text('Version 1.0 · For James & Whitney Mitchell',
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
        const SizedBox(height: 12),

        // Logout button
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout, size: 18, color: AppColors.danger),
            label: Text('Log Out',
                style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.danger)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Out',
            style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.fg)),
        content: Text('Are you sure you want to log out?',
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.fg2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.dmSans(color: AppColors.fg2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log Out',
                style: GoogleFonts.dmSans(
                    color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _authService.signOut();
      // StreamBuilder in main.dart navigates to LoginScreen automatically.
    }
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
