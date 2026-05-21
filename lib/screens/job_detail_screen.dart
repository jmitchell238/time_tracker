import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/entry_category.dart';
import '../models/job.dart';
import '../providers/app_provider.dart';
import '../screens/jobs_screen.dart' show CategoryPickerWidget;
import '../theme/app_theme.dart';
import '../widgets/add_expense_sheet.dart';
import '../widgets/log_time_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/amount_display_pair.dart';
import '../widgets/left_accent_card.dart';
import '../widgets/entry_detail_sheet.dart';

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
    final category = provider.getCategoryForJob(job);
    final headerColor = category?.color ?? AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.of(context).bgDeep,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: headerColor,
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      GestureDetector(
                        onTap: () => _showEditSheet(context, provider, job),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 16, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text('Edit', style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(category.name,
                          style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ],
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
                              LogTimeSheet.show(
                                context,
                                preJobId: widget.jobId,
                                preHours: elapsedH,
                                onConfirmSave: () => provider.stopTimer(widget.jobId),
                              );
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
                // Add Expense button
                SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () => AddExpenseSheet.show(
                      context,
                      preJobId: widget.jobId,
                      preBusinessId: job.businessId,
                    ),
                    icon: const Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.accent),
                    label: Text('Add Expense',
                        style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accent),
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
                      color: job.isArchived ? AppColors.success : AppColors.of(context).fg2,
                    ),
                    label: Text(
                      job.isArchived ? 'Unarchive Job' : 'Archive Job',
                      style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: job.isArchived ? AppColors.success : AppColors.of(context).fg2,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: job.isArchived ? AppColors.success : AppColors.of(context).border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                if (job.isArchived) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDeleteJob(context, provider),
                      icon: const Icon(Icons.delete_forever_outlined, size: 16, color: AppColors.danger),
                      label: Text('Delete Job',
                          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        backgroundColor: AppColors.danger.withAlpha(20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'ALL ENTRIES (${jobEntries.length})',
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.of(context).fg2, letterSpacing: 0.6),
                ),
                const SizedBox(height: 8),
                if (jobEntries.isEmpty)
                  const EmptyStateWidget('No entries yet', verticalPadding: 24),
                ...jobEntries.map((e) {
                  final entryRate = provider.getEntryRate(e);
                  return Dismissible(
                    key: ValueKey(e.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => provider.deleteEntry(e.id),
                    background: const SizedBox.shrink(),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('DELETE',
                          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => EntryDetailSheet.show(context, e),
                        child: LeftAccentCard(
                          accentColor: e.invoiceId != null ? AppColors.of(context).fg3 : AppColors.accent,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_fmtDateShort(e.date),
                                        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
                                    const SizedBox(height: 2),
                                    Text(e.description,
                                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.of(context).fg2)),
                                    const SizedBox(height: 4),
                                    Text(
                                      e.invoiceId != null ? 'Invoiced' : 'Uninvoiced',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 10, fontWeight: FontWeight.w600,
                                        color: e.invoiceId != null ? AppColors.of(context).fg3 : AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AmountDisplayPair(
                                hoursText: '${e.hours.toStringAsFixed(1)}h',
                                amountText: '\$${(e.hours * entryRate).toStringAsFixed(2)}',
                              ),
                            ],
                          ),
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

  void _confirmDeleteJob(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.of(context).bgBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Job?',
            style: GoogleFonts.lora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
        content: Text(
          'This permanently deletes the job. Existing entries will remain but will no longer be linked to it.',
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.of(context).fg2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: AppColors.of(context).fg2)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteJob(widget.jobId);
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close detail screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, AppProvider provider, Job job) {
    final nameCtrl = TextEditingController(text: job.name);
    final descCtrl = TextEditingController(text: job.description);
    final rateCtrl = TextEditingController(
      text: job.rate != null ? job.rate.toString() : '',
    );
    String? selectedCategoryId = job.categoryId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).bgBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final cats = provider.categories;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16, 20, 16,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit Job',
                      style: GoogleFonts.lora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.of(context).fg),
                    decoration: _inputDecoration('Job Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.of(context).fg),
                    decoration: _inputDecoration('Description'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.of(context).fg),
                    decoration: _inputDecoration('Hourly Rate (\$) — leave blank to use default'),
                  ),
                  if (cats.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    CategoryPickerWidget(
                      categories: cats,
                      selectedId: selectedCategoryId,
                      onChanged: (id) => setSheetState(() => selectedCategoryId = id),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        final rateText = rateCtrl.text.trim();
                        final rate = rateText.isNotEmpty ? double.tryParse(rateText) : null;
                        provider.updateJob(
                          job.id,
                          name: name,
                          description: descCtrl.text.trim(),
                          rate: rate,
                          clearRate: rateText.isEmpty,
                          categoryId: selectedCategoryId,
                          clearCategoryId: selectedCategoryId == null,
                        );
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text('Save', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.dmSans(fontSize: 12, color: AppColors.of(context).fg2),
      filled: true,
      fillColor: AppColors.of(context).bgDeep,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.of(context).border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.of(context).border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
