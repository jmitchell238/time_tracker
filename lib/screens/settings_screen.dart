import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../services/csv_import_service.dart';
import '../theme/app_theme.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/section_container.dart';
import '../widgets/segmented_toggle_bar.dart';

class SettingsScreen extends StatefulWidget {
  final AuthService? authService;
  const SettingsScreen({super.key, this.authService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _rateCtrl;
  late TextEditingController _billingNameCtrl;
  late TextEditingController _billingAddressCtrl;
  late TextEditingController _billingPhoneCtrl;
  bool _saved = false;
  bool _importing = false;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
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
        fillColor: AppColors.of(context).bgCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.of(context).border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.of(context).border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text('Settings', style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
        const SizedBox(height: 20),

        // Default hourly rate
        SectionContainer(
          title: 'Default Hourly Rate',
          subtitle: 'Applied to all jobs unless overridden per-job',
          child: Row(
            children: [
              Text('\$', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.dmSans(color: AppColors.of(context).fg, fontSize: 13),
                  decoration: _inputDec(),
                ),
              ),
              const SizedBox(width: 10),
              Text('/ hr', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.of(context).fg2)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Users
        Container(
          decoration: BoxDecoration(
            color: AppColors.of(context).bgCard,
            border: Border.all(color: AppColors.of(context).border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Users', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
                ),
              ),
              Container(height: 1, color: AppColors.of(context).border),
              _userRow('JM', 'James Mitchell', 'jmitchell238@gmail.com'),
              Container(height: 1, color: AppColors.of(context).borderLight),
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

        // Theme
        SectionContainer(
          title: 'THEME',
          child: SegmentedToggleBar(
            labels: const ['Dark', 'Light', 'System'],
            selected: () {
              switch (provider.settings.themeMode) {
                case 'dark': return 'Dark';
                case 'light': return 'Light';
                default: return 'System';
              }
            }(),
            onChanged: (val) {
              final mode = val == 'Dark' ? 'dark' : val == 'Light' ? 'light' : 'system';
              context.read<AppProvider>().updateSettings(
                    provider.settings.copyWith(themeMode: mode));
            },
          ),
        ),
        const SizedBox(height: 20),

        // App info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.of(context).bgCard,
            border: Border.all(color: AppColors.of(context).border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text('Property Work Time Tracker', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.of(context).fg2), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('Version 1.0 · For James & Whitney Mitchell',
                  style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.of(context).fg3), textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Import CSV
        SectionContainer(
          title: 'Data',
          subtitle: 'Import historical time entries from a CSV export',
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _importing ? null : _importCsv,
              icon: _importing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.upload_file, size: 18),
              label: Text(
                _importing ? 'Importing…' : 'Import CSV',
                style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
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

  Future<void> _importCsv() async {
    setState(() => _importing = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (!mounted) return;
      if (result == null || result.files.isEmpty) {
        setState(() => _importing = false);
        return;
      }

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        setState(() => _importing = false);
        _showSnack('Could not read file.');
        return;
      }

      final rows = CsvImportService.parse(utf8.decode(bytes));
      if (rows.isEmpty) {
        setState(() => _importing = false);
        _showSnack('No valid rows found in CSV.');
        return;
      }

      final r = await context.read<AppProvider>().importCsvEntries(rows);
      if (!mounted) return;
      setState(() => _importing = false);

      final msg = StringBuffer('Imported ${r.imported} entr${r.imported == 1 ? 'y' : 'ies'}');
      if (r.skipped > 0) msg.write(', skipped ${r.skipped} duplicate${r.skipped == 1 ? '' : 's'}');
      if (r.jobsCreated > 0) msg.write(', created ${r.jobsCreated} new job${r.jobsCreated == 1 ? '' : 's'}');
      _showSnack(msg.toString());
    } catch (e) {
      if (mounted) {
        setState(() => _importing = false);
        _showSnack('Import failed: $e');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.dmSans())),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Out',
            style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
        content: Text('Are you sure you want to log out?',
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.of(context).fg2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.dmSans(color: AppColors.of(context).fg2)),
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
              Text(name, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
              Text(email, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.of(context).fg2)),
            ],
          ),
        ],
      ),
    );
  }
}
