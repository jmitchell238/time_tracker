import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/time_entry.dart';
import '../theme/app_theme.dart';

class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  String _tab = 'week';
  String? _expandedId;

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

  String _fmtDateShort(String d) {
    final dt = DateTime.parse('${d}T12:00:00');
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  List<TimeEntry> _getVisible(AppProvider provider) {
    final all = [...provider.entries]..sort((a, b) => b.date.compareTo(a.date));
    switch (_tab) {
      case 'day':
        return all.where((e) => e.date == _today()).toList();
      case 'week':
        return all.where((e) => _inRange(e.date, _startOf('week'))).toList();
      case 'month':
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
      final job = provider.jobs.where((j) => j.id == e.jobId).firstOrNull;
      return a + e.hours * provider.getRate(job);
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text('Entries', style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.fg)),
        const SizedBox(height: 14),

        // Tabs
        Container(
          height: 38,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: ['day','week','month','job'].map((t) => _tabBtn(t)).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Summary (not for "job" tab)
        if (_tab != 'job')
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _summaryItem('Hours', '${totalHours.toStringAsFixed(1)}'),
                const SizedBox(width: 20),
                _summaryItem('Earnings', '\$${totalAmount.toStringAsFixed(2)}', color: AppColors.accent),
                const SizedBox(width: 20),
                _summaryItem('Entries', '${visible.length}'),
              ],
            ),
          ),

        if (_tab != 'job') const SizedBox(height: 14),

        // Entries
        if (_tab == 'job')
          _buildByJobTab(provider)
        else
          _buildByDateTab(provider, visible),
      ],
    );
  }

  Widget _buildByDateTab(AppProvider provider, List<TimeEntry> entries) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text('No entries for this period', textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.fg3)),
      );
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
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.fg2)),
              const SizedBox(height: 6),
              ...dateGroup.value.map((e) => _EntryRow(
                    entry: e,
                    provider: provider,
                    expanded: _expandedId == e.id,
                    onToggle: () => setState(() => _expandedId = _expandedId == e.id ? null : e.id),
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

    return Column(
      children: activeJobs.map((job) {
        final jobEs = allEntries.where((e) => e.jobId == job.id).toList();
        if (jobEs.isEmpty) return const SizedBox();
        final jHours = jobEs.fold(0.0, (a, e) => a + e.hours);
        final rate = provider.getRate(job);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(job.name, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  Text('${jHours.toStringAsFixed(1)}h · \$${(jHours * rate).toStringAsFixed(2)}',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              ...jobEs.map((e) => _EntryRow(
                    entry: e,
                    provider: provider,
                    expanded: _expandedId == e.id,
                    onToggle: () => setState(() => _expandedId = _expandedId == e.id ? null : e.id),
                    showDate: true,
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _tabBtn(String tab) {
    final active = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
        child: Container(
          height: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            tab[0].toUpperCase() + tab.substring(1),
            style: GoogleFonts.dmSans(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.fg2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.fg2, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        Text(value, style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: color ?? AppColors.fg)),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  final TimeEntry entry;
  final AppProvider provider;
  final bool expanded;
  final VoidCallback onToggle;
  final bool showDate;

  const _EntryRow({
    required this.entry,
    required this.provider,
    required this.expanded,
    required this.onToggle,
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
    final rate = provider.getRate(job);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: Border(
              left: BorderSide(color: entry.invoiceId != null ? AppColors.fg3 : AppColors.accent, width: 4),
              top: const BorderSide(color: AppColors.border),
              right: const BorderSide(color: AppColors.border),
              bottom: const BorderSide(color: AppColors.border),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDate) ...[
                          Text(_fmtDateShort(entry.date), style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.fg2)),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          entry.description.isNotEmpty ? entry.description : (job?.name ?? 'Entry'),
                          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.fg),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          entry.invoiceId != null ? 'Invoiced' : '● Uninvoiced',
                          style: GoogleFonts.dmSans(
                            fontSize: 10, fontWeight: FontWeight.w600,
                            color: entry.invoiceId != null ? AppColors.fg3 : AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${entry.hours.toStringAsFixed(1)}h',
                          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.fg)),
                      Text('\$${(entry.hours * rate).toStringAsFixed(2)}',
                          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.fg2)),
                    ],
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 10),
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          provider.deleteEntry(entry.id);
                        },
                        icon: const Icon(Icons.delete_outline, size: 15, color: AppColors.danger),
                        label: Text('Delete', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.danger)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.danger, width: 0.5),
                          backgroundColor: AppColors.danger.withAlpha(25),
                          minimumSize: const Size(0, 34),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
