import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/time_entry.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'field_label.dart';

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
  String _jobSearch = '';
  bool _showJobPicker = false;
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
        fillColor: AppColors.bgElevated,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: GoogleFonts.dmSans(color: AppColors.fg3, fontSize: 13),
      );

  Widget _label(String text) => FieldLabel(text);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activeJobs = provider.jobs.where((j) => !j.isArchived).toList();
    final selectedJob =
        activeJobs.where((j) => j.id == _selectedJobId).firstOrNull;
    final filtered = activeJobs
        .where((j) =>
            j.name.toLowerCase().contains(_jobSearch.toLowerCase()))
        .toList();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgBase,
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
                      color: AppColors.border,
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
                          color: AppColors.fg)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.fg2, size: 22),
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
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 14, color: AppColors.fg2),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.entry.date}  ${widget.entry.startTime} – ${widget.entry.endTime}',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.fg2),
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
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showJobPicker = !_showJobPicker),
                      child: Container(
                        height: 44,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bgElevated,
                          border: Border.all(
                              color: _showJobPicker
                                  ? AppColors.primary
                                  : AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedJob?.name ?? 'Select a job…',
                                style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: selectedJob != null
                                        ? AppColors.fg
                                        : AppColors.fg3),
                              ),
                            ),
                            if (_selectedJobId != null)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => setState(() {
                                  _selectedJobId = null;
                                  _rateCtrl.clear();
                                  _showJobPicker = false;
                                }),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.clear,
                                      size: 16, color: AppColors.fg3),
                                ),
                              )
                            else
                              Icon(
                                  _showJobPicker
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: AppColors.fg2,
                                  size: 18),
                          ],
                        ),
                      ),
                    ),
                    if (_showJobPicker) ...[
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: TextField(
                                onChanged: (v) =>
                                    setState(() => _jobSearch = v),
                                style: GoogleFonts.dmSans(
                                    color: AppColors.fg, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Search jobs…',
                                  hintStyle: GoogleFonts.dmSans(
                                      color: AppColors.fg3, fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            const Divider(
                                height: 1, color: AppColors.border),
                            ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxHeight: 160),
                              child: ListView(
                                shrinkWrap: true,
                                children: filtered.map((j) {
                                  final isSel = j.id == _selectedJobId;
                                  return InkWell(
                                    onTap: () => setState(() {
                                      _selectedJobId = j.id;
                                      _showJobPicker = false;
                                      _jobSearch = '';
                                      if (j.rate != null &&
                                          _rateCtrl.text.isEmpty) {
                                        _rateCtrl.text =
                                            j.rate!.toStringAsFixed(2);
                                      }
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      color: isSel
                                          ? AppColors.primary.withAlpha(38)
                                          : Colors.transparent,
                                      child: Text(
                                        j.name,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: isSel
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: isSel
                                              ? AppColors.primary
                                              : AppColors.fg,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Hours
                    _label('Hours Worked'),
                    TextField(
                      controller: _hoursCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: GoogleFonts.dmSans(
                          color: AppColors.fg, fontSize: 13),
                      decoration: _inputDec('0.00'),
                    ),
                    const SizedBox(height: 16),

                    // Rate override
                    _label('Hourly Rate (Optional)'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.only(right: 6, bottom: 2),
                          child: Text('\$',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.fg2, fontSize: 16)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _rateCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: GoogleFonts.dmSans(
                                color: AppColors.fg, fontSize: 13),
                            decoration: _inputDec('0.00'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text('/hr',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.fg2, fontSize: 13)),
                        ),
                      ],
                    ),
                    if (selectedJob?.rate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Job default: \$${selectedJob!.rate!.toStringAsFixed(2)}/hr',
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: AppColors.fg3),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Description
                    _label('Notes / Description'),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      style: GoogleFonts.dmSans(
                          color: AppColors.fg, fontSize: 13),
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
