import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/active_timer.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'job_picker_dropdown.dart';

class ClockOutSheet extends StatefulWidget {
  final ActiveTimer timer;

  const ClockOutSheet({super.key, required this.timer});

  static Future<void> show(BuildContext context, ActiveTimer timer) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClockOutSheet(timer: timer),
    );
  }

  @override
  State<ClockOutSheet> createState() => _ClockOutSheetState();
}

class _ClockOutSheetState extends State<ClockOutSheet> {
  String? _selectedJobId;
  final _descCtrl = TextEditingController();
  late Timer _ticker;
  DateTime _now = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedJobId = widget.timer.jobId;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    _descCtrl.dispose();
    super.dispose();
  }

  String _elapsed() {
    final total = _now.difference(widget.timer.startedAt);
    final breakSecs = widget.timer.totalBreakSeconds +
        (widget.timer.breakStartedAt != null
            ? _now.difference(widget.timer.breakStartedAt!).inSeconds
            : 0);
    final billable =
        Duration(seconds: (total.inSeconds - breakSecs).clamp(0, total.inSeconds));
    final h = billable.inHours;
    final m = billable.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = billable.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String _fmt12(int hour, int minute) {
    final period = hour < 12 ? 'AM' : 'PM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AppProvider>().clockOut(
            widget.timer.id,
            jobId: _selectedJobId,
            description: _descCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clock out failed — check your connection and try again'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.of(context).fg2,
            letterSpacing: 0.6,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activeJobs = provider.jobs.where((j) => !j.isArchived).toList();
    final t = widget.timer;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).bgBase,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 14),
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 18, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Text(
                    'Clock Out',
                    style: GoogleFonts.lora(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.of(context).fg,
                    ),
                  ),
                  const Spacer(),
                  // Live elapsed time
                  Text(
                    _elapsed(),
                    style: GoogleFonts.lora(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.of(context).fg2, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Started at subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 13, color: AppColors.of(context).fg3),
                  const SizedBox(width: 4),
                  Text(
                    'Started ${_fmt12(t.startedAt.hour, t.startedAt.minute)}',
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.of(context).fg2),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job picker
                    _label('Assign to Job (Optional)'),
                    JobPickerDropdown(
                      jobs: activeJobs,
                      selectedJobId: _selectedJobId,
                      placeholder: 'No job assigned',
                      allowDeselect: true,
                      onJobSelected: (id) => setState(() => _selectedJobId = id),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _label('Notes / Description (Optional)'),
                    TextField(
                      controller: _descCtrl,
                      style: GoogleFonts.dmSans(
                          color: AppColors.of(context).fg, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'What did you work on?',
                        hintStyle: GoogleFonts.dmSans(
                            color: AppColors.of(context).fg3, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.of(context).bgCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.of(context).border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.of(context).border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(
                          'Save & Clock Out',
                          style: GoogleFonts.dmSans(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.danger.withValues(alpha: 0.5),
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
