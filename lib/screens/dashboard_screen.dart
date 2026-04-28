import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/log_time_sheet.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final entries = provider.entries;
    final jobs = provider.jobs;
    final settings = provider.settings;

    final weekStart = _startOf('week');
    final monthStart = _startOf('month');
    final yearStart = _startOf('year');

    Map<String, double> sumEntries(List entries) {
      double hours = 0, amount = 0;
      for (final e in entries) {
        final job = jobs.where((j) => j.id == e.jobId).firstOrNull;
        final rate = provider.getRate(job);
        hours += e.hours;
        amount += e.hours * rate;
      }
      return {'hours': hours, 'amount': amount};
    }

    final week = sumEntries(entries.where((e) => _inRange(e.date, weekStart)).toList());
    final month = sumEntries(entries.where((e) => _inRange(e.date, monthStart)).toList());
    final year = sumEntries(entries.where((e) => _inRange(e.date, yearStart)).toList());
    final uninvData = sumEntries(entries.where((e) => e.invoiceId == null).toList());

    final recent = [...entries]
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentFive = recent.take(5).toList();

    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // Greeting
        Text('$greeting, James', style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.fg)),
        const SizedBox(height: 2),
        Text(_fmtDate(_today()), style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.fg2)),
        const SizedBox(height: 20),

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
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.fg2, letterSpacing: 0.6),
        ),
        const SizedBox(height: 10),
        ...recentFive.map((e) {
          final job = jobs.where((j) => j.id == e.jobId).firstOrNull;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                border: Border(
                  left: BorderSide(color: e.invoiceId != null ? AppColors.fg3 : AppColors.accent, width: 4),
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
                        Text(
                          job?.name ?? 'Unknown',
                          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.fg),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e.description,
                          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.fg2),
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
                      Text('${e.hours.toStringAsFixed(1)}h', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.fg)),
                      Text(_fmtDateShort(e.date), style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.fg2)),
                    ],
                  ),
                ],
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
            label: Text('Log Time', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  String _fmtDateShort(String d) {
    final dt = DateTime.parse('${d}T12:00:00');
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
