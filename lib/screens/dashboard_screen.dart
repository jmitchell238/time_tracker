import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/clock_in_sheet.dart';
import '../widgets/entry_edit_sheet.dart';
import '../widgets/log_time_sheet.dart';
import '../widgets/left_accent_card.dart';
import 'job_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

  String _today() => DateTime.now().toIso8601String().substring(0, 10);

  DateTime _startOf(String unit) {
    final now = DateTime.now();
    switch (unit) {
      case 'week':
        return DateTime(now.year, now.month, now.day - now.weekday % 7);
      case 'month':
        return DateTime(now.year, now.month, 1);
      case 'year':
        return DateTime(now.year, 1, 1);
      default:
        return now;
    }
  }

  bool _inRange(String dateStr, DateTime start) {
    final d = DateTime.parse('${dateStr}T12:00:00');
    return !d.isBefore(start);
  }

  String _fmtDate(String d) {
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

  String _fmt12(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final entries = provider.entries;
    final jobs = provider.jobs;

    final weekStart = _startOf('week');
    final monthStart = _startOf('month');
    final yearStart = _startOf('year');

    Map<String, double> sumEntries(List entries) {
      double hours = 0, amount = 0;
      for (final e in entries) {
        final rate = provider.getEntryRate(e);
        hours += e.hours;
        amount += e.hours * rate;
      }
      return {'hours': hours, 'amount': amount};
    }

    final week = sumEntries(entries.where((e) => _inRange(e.date, weekStart)).toList());
    final month = sumEntries(entries.where((e) => _inRange(e.date, monthStart)).toList());
    final year = sumEntries(entries.where((e) => _inRange(e.date, yearStart)).toList());
    final uninvData = sumEntries(provider.invoiceableEntries);

    final recent = [...entries]..sort((a, b) => b.date.compareTo(a.date));
    final recentFive = recent.take(5).toList();

    final hour = _now.hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');

    final incompleteEntries = provider.incompleteEntries;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<AppProvider>().reload(),
      child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // Greeting
        Text('$greeting, James',
            style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
        const SizedBox(height: 2),
        Text(_fmtDate(_today()),
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.of(context).fg2)),
        const SizedBox(height: 16),

        // CLOCK IN button
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () => ClockInSheet.show(context),
            icon: const Icon(Icons.login, size: 20),
            label: Text('CLOCK IN',
                style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Active Jobs section
        if (provider.activeTimers.isNotEmpty) ...[
          Text(
            'ACTIVE JOBS',
            style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success, letterSpacing: 0.6),
          ),
          const SizedBox(height: 8),
          ...provider.activeTimers.map((t) {
            final job = jobs.where((j) => j.id == t.jobId).firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withAlpha(70)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.success, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: t.jobId != null
                              ? () => Navigator.push(context,
                                    MaterialPageRoute(
                                        builder: (_) => JobDetailScreen(jobId: t.jobId!)))
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job?.name ?? 'No Job Assigned',
                                style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: job != null ? AppColors.of(context).fg : AppColors.of(context).fg2),
                              ),
                              Text(
                                _elapsed(t.startedAt),
                                style: GoogleFonts.lora(
                                    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await provider.clockOut(t.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(90, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text('CLOCK OUT',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],

        // Needs Attention section
        if (incompleteEntries.isNotEmpty) ...[
          Text(
            'NEEDS ATTENTION',
            style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 0.6),
          ),
          const SizedBox(height: 8),
          ...incompleteEntries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => EntryEditSheet.show(context, e),
                  child: LeftAccentCard(
                    accentColor: AppColors.accent,
                    outerBorderColor: AppColors.accent.withAlpha(100),
                    contentPadding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No job assigned · ${_fmt12(e.startTime)} – ${_fmt12(e.endTime)}',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.of(context).fg),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _fmtDateShort(e.date),
                                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.of(context).fg2),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${e.hours.toStringAsFixed(1)}h',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
                            Text('Tap to complete',
                                style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.accent)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 8),
        ],

        // Stats row 1
        Row(
          children: [
            StatCard(label: 'This Week', hours: week['hours']!, amount: week['amount']!, accent: true),
            const SizedBox(width: 8),
            StatCard(label: 'This Month', hours: month['hours']!, amount: month['amount']!),
          ],
        ),
        const SizedBox(height: 8),

        // Stats row 2
        Row(
          children: [
            StatCard(label: 'This Year', hours: year['hours']!, amount: year['amount']!),
            const SizedBox(width: 8),
            StatCard(label: 'Uninvoiced', hours: uninvData['hours']!, amount: uninvData['amount']!, gold: true),
          ],
        ),
        const SizedBox(height: 20),

        // Recent entries
        Text(
          'RECENT ENTRIES',
          style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.of(context).fg2, letterSpacing: 0.6),
        ),
        const SizedBox(height: 10),
        ...recentFive.map((e) {
          final job = jobs.where((j) => j.id == e.jobId).firstOrNull;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onTap: e.jobId != null
                  ? () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: e.jobId!)))
                  : () => EntryEditSheet.show(context, e),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.of(context).bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.of(context).border),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                          width: 4,
                          color: e.invoiceId != null ? AppColors.of(context).fg3 : AppColors.accent),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      job?.name ?? 'Unassigned',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.of(context).fg),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      e.description.isNotEmpty
                                          ? e.description
                                          : (job == null ? 'Tap to complete' : ''),
                                      style: GoogleFonts.dmSans(
                                          fontSize: 11, color: AppColors.of(context).fg2),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${e.hours.toStringAsFixed(1)}h',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.of(context).fg)),
                                  Text(_fmtDateShort(e.date),
                                      style: GoogleFonts.dmSans(
                                          fontSize: 11, color: AppColors.of(context).fg2)),
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
            ),
          );
        }),
        const SizedBox(height: 20),

        // Log time button
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => LogTimeSheet.show(context),
            icon: const Icon(Icons.add, size: 18),
            label: Text('Log Time',
                style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
      ),
    );
  }
}
