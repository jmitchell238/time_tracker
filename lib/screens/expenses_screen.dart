import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/expense_item.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_expense_sheet.dart';
import '../widgets/segmented_toggle_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/left_accent_card.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _filter = 'All';
  String? _expandedId;

  String _fmtDateLong(String d) {
    final dt = DateTime.parse('${d}T12:00:00');
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  String _fmtMoney(double n) =>
      '\$${n.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';

  List<ExpenseItem> _filtered(List<ExpenseItem> all) {
    switch (_filter) {
      case 'Pending':
        return all.where((e) => e.invoiceId == null).toList();
      case 'Reimbursed':
        return all.where((e) => e.invoiceId != null).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final allSorted = [...provider.expenses]..sort((a, b) => b.date.compareTo(a.date));
    final visible = _filtered(allSorted);

    final totalSpent = allSorted.fold(0.0, (a, e) => a + e.amount);
    final totalPending = allSorted.where((e) => e.invoiceId == null).fold(0.0, (a, e) => a + e.amount);
    final totalReimbursed = allSorted.where((e) => e.invoiceId != null).fold(0.0, (a, e) => a + e.amount);
    final jamesTotal = allSorted.where((e) => e.purchasedBy == 'James').fold(0.0, (a, e) => a + e.amount);
    final whitneyTotal = allSorted.where((e) => e.purchasedBy == 'Whitney').fold(0.0, (a, e) => a + e.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Row(
          children: [
            Text('Expenses', style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => AddExpenseSheet.show(context),
              icon: const Icon(Icons.add, size: 16),
              label: Text('Add', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Insights summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.of(context).bgBase,
            border: Border.all(color: AppColors.of(context).border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SUMMARY', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.of(context).fg2, letterSpacing: 0.6)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _summaryCell('Total Spent', _fmtMoney(totalSpent), AppColors.of(context).fg),
                  _divider(),
                  _summaryCell('Pending', _fmtMoney(totalPending), AppColors.accent),
                  _divider(),
                  _summaryCell('Reimbursed', _fmtMoney(totalReimbursed), AppColors.success),
                ],
              ),
              if (allSorted.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(height: 1, color: AppColors.of(context).border),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _summaryCell('James', _fmtMoney(jamesTotal), AppColors.primary),
                    _divider(),
                    _summaryCell('Whitney', _fmtMoney(whitneyTotal), AppColors.primary),
                    _divider(),
                    _summaryCell('Items', '${allSorted.length}', AppColors.of(context).fg),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Filter
        SegmentedToggleBar(
          labels: const ['All', 'Pending', 'Reimbursed'],
          selected: _filter,
          onChanged: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 14),

        // List grouped by date
        if (visible.isEmpty)
          const EmptyStateWidget('No expenses yet')
        else
          _buildList(visible, provider),
      ],
    );
  }

  Widget _buildList(List<ExpenseItem> items, AppProvider provider) {
    final byDate = <String, List<ExpenseItem>>{};
    for (final e in items) {
      byDate.putIfAbsent(e.date, () => []).add(e);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: byDate.entries.map((group) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_fmtDateLong(group.key),
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.of(context).fg2)),
              const SizedBox(height: 6),
              ...group.value.map((e) {
                final businessName = e.businessId != null
                    ? provider.businesses
                        .where((b) => b.id == e.businessId)
                        .firstOrNull
                        ?.displayName
                    : null;
                final jobName = e.jobId != null
                    ? provider.jobs
                        .where((j) => j.id == e.jobId)
                        .firstOrNull
                        ?.name
                    : null;
                return _ExpenseRow(
                  expense: e,
                  fmtMoney: _fmtMoney,
                  expanded: _expandedId == e.id,
                  businessName: businessName,
                  jobName: jobName,
                  onToggle: () => setState(
                      () => _expandedId = _expandedId == e.id ? null : e.id),
                  onDelete: () => context.read<AppProvider>().deleteExpense(e.id),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _summaryCell(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.of(context).fg2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: AppColors.of(context).border, margin: const EdgeInsets.symmetric(horizontal: 8));

}

class _ExpenseRow extends StatelessWidget {
  final ExpenseItem expense;
  final String Function(double) fmtMoney;
  final bool expanded;
  final String? businessName;
  final String? jobName;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ExpenseRow({
    required this.expense,
    required this.fmtMoney,
    required this.expanded,
    this.businessName,
    this.jobName,
    required this.onToggle,
    required this.onDelete,
  });

  String _subtitle(bool isPending) {
    final parts = <String>[expense.purchasedBy];
    if (businessName != null) parts.add(businessName!);
    if (jobName != null) parts.add(jobName!);
    parts.add(isPending ? '● Pending' : 'Reimbursed');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final isPending = expense.invoiceId == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onToggle,
        child: LeftAccentCard(
          accentColor: isPending ? AppColors.accent : AppColors.of(context).fg3,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(expense.description,
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.of(context).fg),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text(
                          _subtitle(isPending),
                          style: GoogleFonts.dmSans(
                            fontSize: 10, fontWeight: FontWeight.w600,
                            color: isPending ? AppColors.accent : AppColors.of(context).fg3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(fmtMoney(expense.amount),
                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 10),
                Container(height: 1, color: AppColors.of(context).border),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isPending ? onDelete : null,
                        icon: const Icon(Icons.delete_outline, size: 15, color: AppColors.danger),
                        label: Text(
                          isPending ? 'Delete' : 'Cannot delete — on invoice',
                          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: isPending ? AppColors.danger : AppColors.of(context).fg3),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isPending ? AppColors.danger : AppColors.of(context).border, width: 0.5),
                          backgroundColor: isPending ? AppColors.danger.withAlpha(25) : Colors.transparent,
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
