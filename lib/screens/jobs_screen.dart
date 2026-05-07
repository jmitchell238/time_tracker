import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';
import '../utils/job_sort.dart';
import '../widgets/empty_state.dart';
import 'job_detail_screen.dart';
import '../widgets/left_accent_card.dart';
import '../widgets/active_timer_card.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

enum _SortMode { recent, alphabetical }

class _JobsScreenState extends State<JobsScreen> {
  _SortMode _sortMode = _SortMode.recent;

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

  List<Widget> _buildJobList(AppProvider provider, List<Job> active) {
    final activeJobIds = provider.activeTimers.map((t) => t.jobId).toSet();
    final offClock = active.where((j) => !activeJobIds.contains(j.id)).toList();

    if (offClock.isEmpty) {
      if (provider.activeTimers.isEmpty) {
        return [EmptyStateWidget('No active jobs')];
      }
      return [];
    }

    if (_sortMode == _SortMode.recent) {
      final sorted = sortJobsByRecent(offClock, provider.entries);
      return sorted.map((job) => _JobCard(job: job, provider: provider)).toList();
    }

    // Alphabetical: group by first letter with section headers
    final groups = groupJobsAlphabetically(offClock);
    final widgets = <Widget>[];
    for (final group in groups) {
      widgets.add(_SectionHeader('OFF THE CLOCK – ${group.letter}'));
      for (final job in group.jobs) {
        widgets.add(_JobCard(job: job, provider: provider));
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activeJobs = provider.jobs.where((j) => !j.isArchived).toList();
    final archivedJobs = provider.jobs.where((j) => j.isArchived).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<AppProvider>().reload(),
      child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // Header: logo + title+sort chips on left, Add Job button on right
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/images/logo.png', height: 52),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('Jobs', style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
                    const SizedBox(width: 10),
                    _SortToggle(
                      mode: _sortMode,
                      onChanged: (m) => setState(() => _sortMode = m),
                    ),
                  ],
                ),
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
          if (_sortMode == _SortMode.alphabetical)
            const _SectionHeader('ON THE CLOCK'),
          ...provider.activeTimers.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ActiveTimerCard(key: ValueKey(t.id), timer: t),
              )),
          const SizedBox(height: 8),
        ],

        // Active job list (excludes archived and currently clocked-in jobs)
        ..._buildJobList(provider, activeJobs),

        // Archived jobs — collapsible section at bottom
        if (archivedJobs.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ArchivedSection(jobs: archivedJobs, provider: provider),
        ],
      ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withAlpha(60)),
        ),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _SortToggle extends StatelessWidget {
  final _SortMode mode;
  final ValueChanged<_SortMode> onChanged;

  const _SortToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Chip(
          label: 'Recent',
          icon: Icons.history,
          selected: mode == _SortMode.recent,
          onTap: () => onChanged(_SortMode.recent),
        ),
        const SizedBox(width: 6),
        _Chip(
          label: 'A–Z',
          icon: Icons.sort_by_alpha,
          selected: mode == _SortMode.alphabetical,
          onTap: () => onChanged(_SortMode.alphabetical),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Chip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.of(context).bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.of(context).border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: selected ? Colors.white : AppColors.of(context).fg2),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.of(context).fg2,
                )),
          ],
        ),
      ),
    );
  }
}

class _ArchivedSection extends StatefulWidget {
  final List<Job> jobs;
  final AppProvider provider;

  const _ArchivedSection({required this.jobs, required this.provider});

  @override
  State<_ArchivedSection> createState() => _ArchivedSectionState();
}

class _ArchivedSectionState extends State<_ArchivedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.of(context).bgElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.of(context).border),
            ),
            child: Row(
              children: [
                Icon(Icons.archive_outlined, size: 14, color: AppColors.of(context).fg2),
                const SizedBox(width: 8),
                Text(
                  'Archived Jobs (${widget.jobs.length})',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.of(context).fg2,
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppColors.of(context).fg2,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          ...widget.jobs.map((job) => _JobCard(job: job, provider: widget.provider)),
        ],
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
