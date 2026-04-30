import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'rate_input_field.dart';

class ClockInSheet extends StatefulWidget {
  const ClockInSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ClockInSheet(),
    );
  }

  @override
  State<ClockInSheet> createState() => _ClockInSheetState();
}

class _ClockInSheetState extends State<ClockInSheet> {
  String? _selectedJobId;
  String _jobSearch = '';
  bool _showJobPicker = false;
  final _rateCtrl = TextEditingController();

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  void _clockIn() {
    final provider = context.read<AppProvider>();
    final rateText = _rateCtrl.text.trim();
    final rate = rateText.isEmpty ? null : double.tryParse(rateText);
    provider.clockIn(jobId: _selectedJobId, rateOverride: rate);
    Navigator.pop(context);
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.fg2,
              letterSpacing: 0.6),
        ),
      );

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
                  const Icon(Icons.login, size: 18, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text('Clock In',
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
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job picker
                    _label('Job (Optional)'),
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
                                selectedJob?.name ?? 'No job — add details later',
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
                                  const BoxConstraints(maxHeight: 180),
                              child: ListView(
                                shrinkWrap: true,
                                children: filtered.map((j) {
                                  final isSel = j.id == _selectedJobId;
                                  return InkWell(
                                    onTap: () => setState(() {
                                      _selectedJobId = j.id;
                                      _showJobPicker = false;
                                      _jobSearch = '';
                                      if (j.rate != null) {
                                        _rateCtrl.text =
                                            j.rate!.toStringAsFixed(2);
                                      } else {
                                        _rateCtrl.clear();
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

                    // Rate override
                    _label('Hourly Rate (Optional)'),
                    RateInputField(
                      controller: _rateCtrl,
                      jobDefaultRate: selectedJob?.rate,
                    ),
                    const SizedBox(height: 24),

                    // Clock In button
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _clockIn,
                        icon: const Icon(Icons.timer_outlined, size: 18),
                        label: Text(
                          _selectedJobId != null
                              ? 'Clock In — ${selectedJob?.name ?? ""}'
                              : 'Clock In',
                          style: GoogleFonts.dmSans(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'You can add job & rate details after clocking out',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.fg3),
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
