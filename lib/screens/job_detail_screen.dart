import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class JobDetailScreen extends StatelessWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  String _fmtDateShort(String d) {
    final dt = DateTime.parse('${d}T12:00:00');
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final job = provider.jobs.where((j) => j.id == jobId).firstOrNull;
    if (job == null) return const Scaffold(body: SizedBox());

    final jobEntries = provider.entries
        .where((e) => e.jobId == jobId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final hours = jobEntries.fold(0.0, (a, e) => a + e.hours);
    final rate = provider.getRate(job);

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
                  // Back
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
                // Archive button
                SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      provider.toggleArchiveJob(jobId);
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('No entries yet', textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.fg3)),
                  ),
                ...jobEntries.map((e) {
                  final entryRate = provider.getRate(job);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        border: Border(
                          left: BorderSide(
                            color: e.invoiceId != null ? AppColors.fg3 : AppColors.accent,
                            width: 4,
                          ),
                          top: const BorderSide(color: AppColors.border),
                          right: const BorderSide(color: AppColors.border),
                          bottom: const BorderSide(color: AppColors.border),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
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
        Text(label.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
        Text(value, style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w700, color: valueColor, height: 1.1)),
      ],
    );
  }
}
