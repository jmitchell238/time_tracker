import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import 'job_picker_dropdown.dart';
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
    Analytics.action('clock_in_confirmed', properties: {
      'has_job': _selectedJobId != null,
      'has_rate_override': rate != null,
    });
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
              color: AppColors.of(context).fg2,
              letterSpacing: 0.6),
        ),
      );

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
                  const Icon(Icons.login, size: 18, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text('Clock In',
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
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job picker
                    _label('Job (Optional)'),
                    JobPickerDropdown(
                      jobs: activeJobs,
                      selectedJobId: _selectedJobId,
                      placeholder: 'No job — add details later',
                      allowDeselect: true,
                      onJobSelected: (id) {
                        setState(() => _selectedJobId = id);
                        if (id == null) {
                          _rateCtrl.clear();
                        } else {
                          final job = activeJobs.where((j) => j.id == id).firstOrNull;
                          if (job?.rate != null) {
                            _rateCtrl.text = job!.rate!.toStringAsFixed(2);
                          } else {
                            _rateCtrl.clear();
                          }
                        }
                      },
                    ),
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
                            fontSize: 11, color: AppColors.of(context).fg3),
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
