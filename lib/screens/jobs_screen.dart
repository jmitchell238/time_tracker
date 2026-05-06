import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';
import '../widgets/segmented_toggle_bar.dart';
import '../widgets/empty_state.dart';
import 'job_detail_screen.dart';
import '../widgets/left_accent_card.dart';
import '../widgets/active_timer_card.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  bool _showArchived = false;

  Future<void> _showAddJobDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    var saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          backgroundColor: AppColors.of(context).bgBase,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add Job', style: GoogleFonts.lora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameCtrl, 'Job name *'),
              const SizedBox(height: 12),
              _dialogField(descCtrl, 'Description (optional)'),
              const SizedBox(height: 12),
              _dialogField(rateCtrl, 'Hourly rate override (optional)', numeric: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.dmSans(color: AppColors.of(context).fg2)),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      setDialogState(() => saving = true);
                      try {
                        await context.read<AppProvider>().addJob(
                              name,
                              descCtrl.text.trim(),
                              double.tryParse(rateCtrl.text.trim()),
                            );
                        if (context.mounted) Navigator.pop(context);
                      } catch (_) {
                        setDialogState(() => saving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Save failed — check your connection and try again'),
                              backgroundColor: Color(0xFFE53935),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Add', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  TextField _dialogField(TextEditingController ctrl, String hint, {bool numeric = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: GoogleFonts.dmSans(color: AppColors.of(context).fg, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(color: AppColors.of(context).fg3, fontSize: 13),
        filled: true,
        fillColor: AppColors.of(context).bgElevated,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final visible = provider.jobs.where((j) => j.isArchived == _showArchived).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // Header
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/images/logo.png', height: 28),
                const SizedBox(height: 2),
                Text('Jobs', style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showAddJobDialog,
              icon: const Icon(Icons.add, size: 16),
              label: Text('Add Job', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Active timers pinned at top
        if (provider.activeTimers.isNotEmpty) ...[
          ...provider.activeTimers.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ActiveTimerCard(key: ValueKey(t.id), timer: t),
              )),
          const SizedBox(height: 8),
        ],

        // Active/Archived toggle
        SegmentedToggleBar(
          labels: const ['Active', 'Archived'],
          selected: _showArchived ? 'Archived' : 'Active',
          onChanged: (v) => setState(() => _showArchived = v == 'Archived'),
        ),
        const SizedBox(height: 16),

        // Job list
        if (visible.isEmpty)
          EmptyStateWidget('No ${_showArchived ? 'archived' : 'active'} jobs'),
        ...visible.map((job) => _JobCard(job: job, provider: provider)),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  final AppProvider provider;
  const _JobCard({required this.job, required this.provider});

  @override
  Widget build(BuildContext context) {
    final jobEntries = provider.entries.where((e) => e.jobId == job.id).toList();
    final hours = jobEntries.fold(0.0, (a, e) => a + e.hours);
    final rate = provider.getRate(job);
    final amount = hours * rate;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id)),
        ),
        child: LeftAccentCard(
          accentColor: AppColors.primary,
          borderRadius: 12,
          contentPadding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.name, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
                    if (job.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(job.description, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.of(context).fg2)),
                    ],
                    if (job.rate != null) ...[
                      const SizedBox(height: 4),
                      Text('\$${job.rate!.toStringAsFixed(0)}/hr override',
                          style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${hours.toStringAsFixed(1)}h',
                      style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
                  Text('\$${amount.toStringAsFixed(2)}',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: AppColors.of(context).fg3, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
