import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/time_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/segmented_toggle_bar.dart';
import '../widgets/metric_item.dart';
import '../widgets/empty_state.dart';
import '../widgets/amount_display_pair.dart';
import '../widgets/left_accent_card.dart';
import '../widgets/entry_detail_sheet.dart';

class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  String _tab = 'Week';

  String _today() => DateTime.now().toIso8601String().substring(0, 10);

  DateTime _startOf(String unit) {
    final now = DateTime.now();
    switch (unit) {
      case 'week':
        return DateTime(now.year, now.month, now.day - now.weekday % 7);
      case 'month':
        return DateTime(now.year, now.month, 1);
      default:
        return now;
    }
  }

  bool _inRange(String dateStr, DateTime start) {
    final d = DateTime.parse('${dateStr}T12:00:00');
    return !d.isBefore(start);
  }

  String _fmtDateLong(String d) {
    final dt = DateTime.parse('${d}T12:00:00');
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  List<TimeEntry> _getVisible(AppProvider provider) {
    final all = [...provider.entries]..sort((a, b) => b.date.compareTo(a.date));
    switch (_tab) {
      case 'Day':
        return all.where((e) => e.date == _today()).toList();
      case 'Week':
        return all.where((e) => _inRange(e.date, _startOf('week'))).toList();
      case 'Month':
        return all.where((e) => _inRange(e.date, _startOf('month'))).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final visible = _getVisible(provider);

    final totalHours = visible.fold(0.0, (a, e) => a + e.hours);
    final totalAmount = visible.fold(0.0, (a, e) {
      return a + e.hours * provider.getEntryRate(e);
    });

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<AppProvider>().reload(),
      child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text('Entries', style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
        const SizedBox(height: 14),

        // Tabs
        SegmentedToggleBar(
          labels: const ['Day', 'Week', 'Month', 'Job'],
          selected: _tab,
          onChanged: (v) => setState(() => _tab = v),
        ),
        const SizedBox(height: 14),

        // Summary (not for "job" tab)
        if (_tab != 'Job')
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                MetricItem(label: 'Hours', value: totalHours.toStringAsFixed(1)),
                const SizedBox(width: 20),
                MetricItem(label: 'Earnings', value: '\$${totalAmount.toStringAsFixed(2)}', color: AppColors.accent),
                const SizedBox(width: 20),
                MetricItem(label: 'Entries', value: '${visible.length}'),
              ],
            ),
          ),

        if (_tab != 'Job') const SizedBox(height: 14),

        // Entries
        if (_tab == 'Job')
          _buildByJobTab(provider)
        else
          _buildByDateTab(provider, visible),
      ],
      ),
    );
  }

  Widget _buildByDateTab(AppProvider provider, List<TimeEntry> entries) {
    if (entries.isEmpty) {
      return const EmptyStateWidget('No entries for this period');
    }

    final byDate = <String, List<TimeEntry>>{};
    for (final e in entries) {
      byDate.putIfAbsent(e.date, () => []).add(e);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: byDate.entries.map((dateGroup) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_fmtDateLong(dateGroup.key),
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.of(context).fg2)),
              const SizedBox(height: 6),
              ...dateGroup.value.map((e) => _EntryRow(
                    entry: e,
                    provider: provider,
                    showDate: false,
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildByJobTab(AppProvider provider) {
    final activeJobs = provider.jobs.where((j) => !j.isArchived).toList();
    final allEntries = [...provider.entries]..sort((a, b) => b.date.compareTo(a.date));
    final unassigned = allEntries.where((e) => e.jobId == null).toList();

    return Column(
      children: [
        // Unassigned group
        if (unassigned.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Unassigned',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
                    Text('${unassigned.fold(0.0, (a, e) => a + e.hours).toStringAsFixed(1)}h',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.of(context).fg2, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                ...unassigned.map((e) => _EntryRow(
                      entry: e,
                      provider: provider,
                      showDate: true,
                    )),
              ],
            ),
          ),
        ],
        // Per-job groups
        ...activeJobs.map((job) {
          final jobEs = allEntries.where((e) => e.jobId == job.id).toList();
          if (jobEs.isEmpty) return const SizedBox();
          final jHours = jobEs.fold(0.0, (a, e) => a + e.hours);
          final jAmount = jobEs.fold(0.0, (a, e) => a + e.hours * provider.getEntryRate(e));

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(job.name,
                        style: GoogleFonts.dmSans(
                            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    Text('${jHours.toStringAsFixed(1)}h · \$${jAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                ...jobEs.map((e) => _EntryRow(
                      entry: e,
                      provider: provider,
                      showDate: true,
                    )),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  final TimeEntry entry;
  final AppProvider provider;
  final bool showDate;

  const _EntryRow({
    required this.entry,
    required this.provider,
    required this.showDate,
  });

  String _fmtDateShort(String d) {
    final dt = DateTime.parse('${d}T12:00:00');
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final job = provider.jobs.where((j) => j.id == entry.jobId).firstOrNull;
    final rate = provider.getEntryRate(entry);

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => provider.deleteEntry(entry.id),
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('DELETE',
            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GestureDetector(
          onTap: () => EntryDetailSheet.show(context, entry),
          child: LeftAccentCard(
            accentColor: entry.invoiceId != null ? AppColors.of(context).fg3 : AppColors.accent,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDate) ...[
                        Text(_fmtDateShort(entry.date), style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.of(context).fg2)),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        entry.description.isNotEmpty ? entry.description : (job?.name ?? 'Unassigned'),
                        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.of(context).fg),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        entry.invoiceId != null ? 'Invoiced' : '● Uninvoiced',
                        style: GoogleFonts.dmSans(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: entry.invoiceId != null ? AppColors.of(context).fg3 : AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AmountDisplayPair(
                  hoursText: '${entry.hours.toStringAsFixed(1)}h',
                  amountText: '\$${(entry.hours * rate).toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
