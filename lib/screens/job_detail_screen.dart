import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/log_time_sheet.dart';
import '../widgets/empty_state.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _elapsed(DateTime startedAt) {
    final diff = _now.difference(startedAt);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double _elapsedHours(DateTime startedAt) {
    return _now.difference(startedAt).inSeconds / 3600.0;
  }

  String _fmtDateShort(String d) {
    final dt = DateTime.parse('${d}T12:00:00');
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final job = provider.jobs.where((j) => j.id == widget.jobId).firstOrNull;
    if (job == null) return const Scaffold(body: SizedBox());

    final jobEntries = provider.entries
        .where((e) => e.jobId == widget.jobId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final hours = jobEntries.fold(0.0, (a, e) => a + e.hours);
    final rate = provider.getRate(job);
    final isRunning = provider.isTimerRunning(widget.jobId);
    final activeTimer = provider.getTimer(widget.jobId);

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.primary,
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back, size: 18, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text('Back', style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(job.name, style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  if (job.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(job.description, style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white60)),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _statChip('Total Hours', '${hours.toStringAsFixed(1)}h', Colors.white),
                      const SizedBox(width: 24),
                      _statChip('Earnings', '\$${(hours * rate).toStringAsFixed(2)}', AppColors.accent),
                      const SizedBox(width: 24),
                      _statChip('Rate', '\$$rate/h', Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Timer section
                if (isRunning && activeTimer != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withAlpha(80)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text('TIMER RUNNING',
                                style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 0.6)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _elapsed(activeTimer.startedAt),
                          style: GoogleFonts.lora(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.accent, height: 1),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final elapsedH = _elapsedHours(activeTimer.startedAt);
                              provider.stopTimer(widget.jobId);
                              LogTimeSheet.show(context, preJobId: widget.jobId, preHours: elapsedH);
                            },
                            icon: const Icon(Icons.stop, size: 16),
                            label: Text('Stop & Log Time',
                                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  SizedBox(
                    height: 40,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => provider.startTimer(widget.jobId),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: Text('Start Timer',
                          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Log Time button
                SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () => LogTimeSheet.show(context, preJobId: widget.jobId),
                    icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                    label: Text('Log Time',
                        style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Archive button
                SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      provider.toggleArchiveJob(widget.jobId);
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      job.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                      size: 16,
                      color: job.isArchived ? AppColors.success : AppColors.fg2,
                    ),
                    label: Text(
                      job.isArchived ? 'Unarchive Job' : 'Archive Job',
                      style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: job.isArchived ? AppColors.success : AppColors.fg2,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: job.isArchived ? AppColors.success : AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ALL ENTRIES (${jobEntries.length})',
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.fg2, letterSpacing: 0.6),
                ),
                const SizedBox(height: 8),
                if (jobEntries.isEmpty)
                  const EmptyStateWidget('No entries yet', verticalPadding: 24),
                ...jobEntries.map((e) {
                  final entryRate = provider.getEntryRate(e);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(width: 4, color: e.invoiceId != null ? AppColors.fg3 : AppColors.accent),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_fmtDateShort(e.date),
                                              style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.fg)),
                                          const SizedBox(height: 2),
                                          Text(e.description,
                                              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.fg2)),
                                          const SizedBox(height: 4),
                                          Text(
                                            e.invoiceId != null ? 'Invoiced' : 'Uninvoiced',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 10, fontWeight: FontWeight.w600,
                                              color: e.invoiceId != null ? AppColors.fg3 : AppColors.accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('${e.hours.toStringAsFixed(1)}h',
                                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.fg)),
                                        Text('\$${(e.hours * entryRate).toStringAsFixed(2)}',
                                            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.fg2)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
        Text(value,
            style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w700, color: valueColor, height: 1.1)),
      ],
    );
  }
}
