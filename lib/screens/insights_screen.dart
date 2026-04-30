import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/job.dart';
import '../models/time_entry.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

enum _Period { allTime, currentMonth, lastMonth, currentYear, lastYear }

extension _PeriodLabel on _Period {
  String get label {
    switch (this) {
      case _Period.allTime:        return 'All Time';
      case _Period.currentMonth:   return 'This Month';
      case _Period.lastMonth:      return 'Last Month';
      case _Period.currentYear:    return 'This Year';
      case _Period.lastYear:       return 'Last Year';
    }
  }
}

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  _Period _period = _Period.allTime;
  String? _selectedJobId; // null = All Jobs

  bool _inPeriod(TimeEntry e) {
    final now = DateTime.now();
    final d = e.date;
    switch (_period) {
      case _Period.allTime:
        return true;
      case _Period.currentMonth:
        return d.startsWith('${now.year}-${_p2(now.month)}');
      case _Period.lastMonth:
        final prev = DateTime(now.year, now.month - 1);
        return d.startsWith('${prev.year}-${_p2(prev.month)}');
      case _Period.currentYear:
        return d.startsWith('${now.year}');
      case _Period.lastYear:
        return d.startsWith('${now.year - 1}');
    }
  }

  static String _p2(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final allJobs = [...prov.jobs]..sort((a, b) => a.name.compareTo(b.name));

    final filtered = prov.entries.where(_inPeriod).toList();
    final forJob = _selectedJobId == null
        ? filtered
        : filtered.where((e) => e.jobId == _selectedJobId).toList();

    double hours = 0, earned = 0;
    for (final e in forJob) {
      hours += e.hours;
      earned += e.hours * prov.getEntryRate(e);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text('Insights',
            style: GoogleFonts.lora(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.fg)),
        const SizedBox(height: 16),
        _buildPeriodChips(),
        const SizedBox(height: 12),
        _buildJobDropdown(allJobs),
        const SizedBox(height: 16),
        _buildSummaryRow(hours: hours, earned: earned, count: forJob.length),
        const SizedBox(height: 20),
        if (_selectedJobId == null)
          _buildAllJobsBreakdown(filtered, prov.jobs, prov.getEntryRate)
        else
          _buildSingleJobBreakdown(forJob, prov.getEntryRate),
      ],
    );
  }

  Widget _buildPeriodChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _Period.values.map((p) {
          final active = _period == p;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _period = p),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active ? AppColors.primary : AppColors.border),
                ),
                child: Text(
                  p.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? Colors.white : AppColors.fg2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildJobDropdown(List<Job> jobs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedJobId,
          dropdownColor: AppColors.bgBase,
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.fg),
          isExpanded: true,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('All Jobs',
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.fg)),
            ),
            ...jobs.map((j) => DropdownMenuItem<String?>(
                  value: j.id,
                  child: Text(j.name,
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppColors.fg)),
                )),
          ],
          onChanged: (v) => setState(() => _selectedJobId = v),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      {required double hours, required double earned, required int count}) {
    return Row(
      children: [
        Expanded(
            child: _statCard(
                'Hours', hours.toStringAsFixed(1), Icons.access_time_outlined)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard('Earned', '\$${earned.toStringAsFixed(2)}',
                Icons.attach_money_outlined)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard('Entries', '$count', Icons.list_alt_outlined)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.accent),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.lora(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.fg)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.fg3)),
        ],
      ),
    );
  }

  // ── All Jobs breakdown ────────────────────────────────────────────────────

  Widget _buildAllJobsBreakdown(
    List<TimeEntry> filtered,
    List<Job> allJobs,
    double Function(TimeEntry) getRate,
  ) {
    if (filtered.isEmpty) return _empty('No entries for this period');

    final Map<String?, _Stat> stats = {};
    for (final e in filtered) {
      final s = stats.putIfAbsent(e.jobId, () => _Stat());
      s.hours += e.hours;
      s.earned += e.hours * getRate(e);
      s.count++;
    }

    final rows = stats.entries.toList()
      ..sort((a, b) => b.value.hours.compareTo(a.value.hours));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('By Job'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: List.generate(rows.length, (i) {
              final kv = rows[i];
              final jobName = kv.key == null
                  ? 'Uncategorized'
                  : allJobs
                          .where((j) => j.id == kv.key)
                          .firstOrNull
                          ?.name ??
                      '—';
              final st = kv.value;
              return Column(
                children: [
                  if (i > 0)
                    Container(height: 1, color: AppColors.borderLight),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(jobName,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.fg)),
                              Text(
                                  '${st.count} '
                                  'entr${st.count == 1 ? 'y' : 'ies'}',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 10, color: AppColors.fg3)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${st.hours.toStringAsFixed(1)} hrs',
                                style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.fg)),
                            Text('\$${st.earned.toStringAsFixed(2)}',
                                style: GoogleFonts.dmSans(
                                    fontSize: 11, color: AppColors.accent)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── Single Job breakdown ──────────────────────────────────────────────────

  Widget _buildSingleJobBreakdown(
    List<TimeEntry> entries,
    double Function(TimeEntry) getRate,
  ) {
    if (entries.isEmpty) {
      return _empty('No entries for this job in this period');
    }

    final Map<String, List<TimeEntry>> byMonth = {};
    for (final e in entries) {
      byMonth.putIfAbsent(e.date.substring(0, 7), () => []).add(e);
    }
    final months = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('By Month'),
        const SizedBox(height: 8),
        ...months.map((month) {
          final mes = byMonth[month]!
            ..sort((a, b) => b.date.compareTo(a.date));
          final mh = mes.fold<double>(0, (s, e) => s + e.hours);
          final me =
              mes.fold<double>(0, (s, e) => s + e.hours * getRate(e));

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmtMonth(month),
                            style: GoogleFonts.lora(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.fg)),
                        Row(
                          children: [
                            Text('${mh.toStringAsFixed(1)} hrs',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.fg)),
                            const SizedBox(width: 8),
                            Text('\$${me.toStringAsFixed(2)}',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12, color: AppColors.accent)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: AppColors.border),
                  ...List.generate(mes.length, (i) {
                    final e = mes[i];
                    return Column(
                      children: [
                        if (i > 0)
                          Container(height: 1, color: AppColors.borderLight),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 44,
                                child: Text(_fmtDateShort(e.date),
                                    style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: AppColors.fg3,
                                        fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.description.isEmpty
                                      ? '(no description)'
                                      : e.description,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12, color: AppColors.fg2),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${e.hours.toStringAsFixed(1)}h',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.fg)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.fg3,
          letterSpacing: 0.8));

  Widget _empty(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(msg,
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.fg3),
              textAlign: TextAlign.center),
        ),
      );

  static String _fmtMonth(String yyyyMm) {
    final p = yyyyMm.split('-');
    const m = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${m[int.parse(p[1]) - 1]} ${p[0]}';
  }

  static String _fmtDateShort(String d) {
    final dt = DateTime.parse('${d}T12:00:00');
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[dt.month - 1]} ${dt.day}';
  }
}

class _Stat {
  double hours = 0;
  double earned = 0;
  int count = 0;
}
