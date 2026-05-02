import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/time_entry.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'field_label.dart';
import 'job_picker_dropdown.dart';
import 'rate_input_field.dart';

class EntryEditSheet extends StatefulWidget {
  final TimeEntry entry;

  const EntryEditSheet({super.key, required this.entry});

  static Future<void> show(BuildContext context, TimeEntry entry) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EntryEditSheet(entry: entry),
    );
  }

  @override
  State<EntryEditSheet> createState() => _EntryEditSheetState();
}

class _EntryEditSheetState extends State<EntryEditSheet> {
  String? _selectedJobId;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _selectedJobId = widget.entry.jobId;
    _hoursCtrl = TextEditingController(
        text: widget.entry.hours.toStringAsFixed(2));
    _rateCtrl = TextEditingController(
        text: widget.entry.rateOverride?.toStringAsFixed(2) ?? '');
    _descCtrl = TextEditingController(text: widget.entry.description);
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    _rateCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final provider = context.read<AppProvider>();
    final hours = double.tryParse(_hoursCtrl.text.trim()) ?? widget.entry.hours;
    final rateText = _rateCtrl.text.trim();
    final rate = rateText.isEmpty ? null : double.tryParse(rateText);
    final desc = _descCtrl.text.trim();

    provider.updateEntry(
      widget.entry.id,
      jobId: _selectedJobId,
      clearJobId: _selectedJobId == null,
      hours: hours,
      rateOverride: rate,
      clearRateOverride: rate == null,
      description: desc,
    );
    Navigator.pop(context);
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.of(context).bgElevated,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.of(context).border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.of(context).border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: GoogleFonts.dmSans(color: AppColors.of(context).fg3, fontSize: 13),
      );

  Widget _label(String text) => FieldLabel(text);

  String _fmt12(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activeJobs = provider.jobs.where((j) => !j.isArchived).toList();
    final selectedJob =
        activeJobs.where((j) => j.id == _selectedJobId).firstOrNull;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).bgBase,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.of(context).border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 14),
              child: Row(
                children: [
                  const Icon(Icons.edit_note,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('Complete Entry',
                      style: GoogleFonts.lora(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.of(context).fg)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: AppColors.of(context).fg2, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Entry date/time summary
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.of(context).bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.of(context).border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule,
                        size: 14, color: AppColors.of(context).fg2),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.entry.date}  ${_fmt12(widget.entry.startTime)} – ${_fmt12(widget.entry.endTime)}',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.of(context).fg2),
                    ),
                  ],
                ),
              ),
            ),
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job picker
                    _label('Job'),
                    JobPickerDropdown(
                      jobs: activeJobs,
                      selectedJobId: _selectedJobId,
                      allowDeselect: true,
                      maxDropdownHeight: 160,
                      onJobSelected: (id) {
                        setState(() => _selectedJobId = id);
                        if (id == null) {
                          _rateCtrl.clear();
                        } else {
                          final job = activeJobs.where((j) => j.id == id).firstOrNull;
                          if (job?.rate != null && _rateCtrl.text.isEmpty) {
                            _rateCtrl.text = job!.rate!.toStringAsFixed(2);
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Hours
                    _label('Hours Worked'),
                    TextField(
                      controller: _hoursCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: GoogleFonts.dmSans(
                          color: AppColors.of(context).fg, fontSize: 13),
                      decoration: _inputDec('0.00'),
                    ),
                    const SizedBox(height: 16),

                    // Rate override
                    _label('Hourly Rate (Optional)'),
                    RateInputField(
                      controller: _rateCtrl,
                      jobDefaultRate: selectedJob?.rate,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _label('Notes / Description'),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      style: GoogleFonts.dmSans(
                          color: AppColors.of(context).fg, fontSize: 13),
                      decoration: _inputDec('What did you work on?'),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(
                          'Save Entry',
                          style: GoogleFonts.dmSans(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
