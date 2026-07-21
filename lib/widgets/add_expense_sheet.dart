import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';

class AddExpenseSheet {
  static void show(
    BuildContext context, {
    String? preJobId,
    String? preBusinessId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).bgBase,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _AddExpenseSheetBody(
        preJobId: preJobId,
        preBusinessId: preBusinessId,
      ),
    );
  }
}

class _AddExpenseSheetBody extends StatefulWidget {
  final String? preJobId;
  final String? preBusinessId;

  const _AddExpenseSheetBody({this.preJobId, this.preBusinessId});

  @override
  State<_AddExpenseSheetBody> createState() => _AddExpenseSheetBodyState();
}

class _AddExpenseSheetBodyState extends State<_AddExpenseSheetBody> {
  late TextEditingController _descCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _dateCtrl;
  String _purchasedBy = 'James';
  String? _selectedBusinessId;
  String? _selectedJobId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _dateCtrl = TextEditingController(
        text: DateTime.now().toIso8601String().substring(0, 10));
    _selectedBusinessId = widget.preBusinessId;
    _selectedJobId = widget.preJobId;

    // If a job is pre-selected, auto-select its business
    if (_selectedJobId != null && _selectedBusinessId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<AppProvider>();
        final job = provider.jobs.where((j) => j.id == _selectedJobId).firstOrNull;
        if (job?.businessId != null) {
          setState(() => _selectedBusinessId = job!.businessId);
        }
      });
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  bool _canSave(AppProvider provider) {
    final desc = _descCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    final date = _dateCtrl.text.trim();
    if (desc.isEmpty || amount == null || date.isEmpty) return false;
    // Must be tied to something: a business or a job. If neither businesses
    // nor jobs exist yet, allow saving unlinked.
    final hasLinkTargets =
        provider.businesses.isNotEmpty || provider.jobs.any((j) => !j.isArchived);
    if (hasLinkTargets && _selectedBusinessId == null && _selectedJobId == null) {
      return false;
    }
    return true;
  }

  Future<void> _save(AppProvider provider) async {
    final desc = _descCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    final date = _dateCtrl.text.trim();
    if (desc.isEmpty || amount == null || date.isEmpty) return;
    Analytics.action('expense_saved', properties: {
      'amount': amount,
      'purchased_by': _purchasedBy,
      'has_business': _selectedBusinessId != null,
      'has_job': _selectedJobId != null,
    });
    setState(() => _saving = true);
    try {
      await provider.addExpense(
        description: desc,
        amount: amount,
        date: date,
        purchasedBy: _purchasedBy,
        businessId: _selectedBusinessId,
        jobId: _selectedJobId,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save failed — check your connection and try again'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final businesses = provider.businesses;

    // Jobs filtered to selected business, else all active jobs
    final jobs = provider.jobs.where((j) => !j.isArchived).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    // When a business is selected, show its jobs — but always keep the
    // currently-selected job visible even if it isn't tied to that business.
    final filteredJobs = _selectedBusinessId != null
        ? jobs
            .where((j) =>
                j.businessId == _selectedBusinessId || j.id == _selectedJobId)
            .toList()
        : jobs;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Expense',
                style: GoogleFonts.lora(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.of(context).fg)),
            const SizedBox(height: 20),

            // Business (required)
            _sectionLabel('BUSINESS (optional)'),
            const SizedBox(height: 8),
            if (businesses.isEmpty)
              Text('No businesses saved yet — expense will be saved without one.',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.of(context).fg3))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: businesses.map((b) {
                  final active = _selectedBusinessId == b.id;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedBusinessId = active ? null : b.id;
                    }),
                    child: _chip(b.displayName, active),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),

            // Job (optional)
            _sectionLabel('LINKED JOB (optional)'),
            const SizedBox(height: 8),
            if (filteredJobs.isEmpty)
              Text(
                _selectedBusinessId != null
                    ? 'No active jobs for this business.'
                    : 'No active jobs.',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.of(context).fg3),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filteredJobs.map((j) {
                  final active = _selectedJobId == j.id;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedJobId = active ? null : j.id;
                    }),
                    child: _chip(j.name, active, activeColor: AppColors.success),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),

            // Description
            _field(_descCtrl, 'Description (e.g. Hydraulic fluid)'),
            const SizedBox(height: 12),

            // Amount
            _field(_amountCtrl, 'Amount (\$)',
                keyboard: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 12),

            // Date
            _field(_dateCtrl, 'Date (YYYY-MM-DD)'),
            const SizedBox(height: 14),

            // Purchased by
            _sectionLabel('PURCHASED BY'),
            const SizedBox(height: 8),
            Row(
              children: ['James', 'Whitney'].map((name) {
                final active = _purchasedBy == name;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _purchasedBy = name),
                    child: Container(
                      margin: EdgeInsets.only(right: name == 'James' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.of(context).bgDeep,
                        border: Border.all(
                            color: active ? AppColors.primary : AppColors.of(context).border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(name,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: active ? Colors.white : AppColors.of(context).fg2,
                            )),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_canSave(provider) && !_saving) ? () => _save(provider) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.of(context).bgElevated,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Save',
                        style: GoogleFonts.dmSans(
                            fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.of(context).fg2,
          letterSpacing: 0.6));

  Widget _chip(String label, bool active, {Color? activeColor}) {
    final color = activeColor ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? color.withAlpha(30) : AppColors.of(context).bgDeep,
        border: Border.all(color: active ? color : AppColors.of(context).border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? color : AppColors.of(context).fg2)),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.of(context).fg),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 12, color: AppColors.of(context).fg2),
        filled: true,
        fillColor: AppColors.of(context).bgDeep,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.of(context).border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.of(context).border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
