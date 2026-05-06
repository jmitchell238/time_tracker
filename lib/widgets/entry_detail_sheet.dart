import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/time_entry.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'entry_edit_form_sheet.dart';

class EntryDetailSheet extends StatelessWidget {
  final TimeEntry entry;

  const EntryDetailSheet({super.key, required this.entry});

  static Future<void> show(BuildContext context, TimeEntry entry) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EntryDetailSheet(entry: entry),
    );
  }

  bool get _isTimeBased =>
      !(entry.startTime == '00:00' && entry.endTime == '00:00');

  String _fmt12(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $period';
  }

  String _formatDate(String date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final parts = date.split('-');
    if (parts.length != 3) return date;
    final month = int.tryParse(parts[1]);
    final monthName =
        (month != null && month >= 1 && month <= 12) ? months[month - 1] : parts[1];
    return '$monthName ${int.parse(parts[2])}, ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final job = provider.jobs.where((j) => j.id == entry.jobId).firstOrNull;
    final rate = provider.getEntryRate(entry);
    final earnings = entry.hours * rate;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).bgBase,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 14),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Text('Entry Details',
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
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: _formatDate(entry.date),
                  ),
                  const SizedBox(height: 12),
                  if (_isTimeBased) ...[
                    _DetailRow(
                      icon: Icons.schedule_outlined,
                      label: 'Time',
                      value:
                          '${_fmt12(entry.startTime)} – ${_fmt12(entry.endTime)}',
                    ),
                    const SizedBox(height: 12),
                  ],
                  _DetailRow(
                    icon: Icons.timer_outlined,
                    label: 'Hours',
                    value: '${entry.hours.toStringAsFixed(2)} hrs',
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.work_outline,
                    label: 'Job',
                    value: job?.name ?? '(No job)',
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.attach_money,
                    label: 'Earnings',
                    value:
                        '\$${earnings.toStringAsFixed(2)} @ \$${rate.toStringAsFixed(0)}/hr',
                  ),
                  if (entry.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.notes_outlined,
                      label: 'Notes',
                      value: entry.description,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        EntryEditFormSheet.show(context, entry);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text('Edit Entry',
                          style: GoogleFonts.dmSans(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
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
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.of(context).fg2),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.of(context).fg3,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.of(context).fg,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
