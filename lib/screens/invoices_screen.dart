import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/invoice.dart';
import '../models/expense_item.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_item.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/amount_display_pair.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  bool _creating = false;
  String? _detailId;
  // 'all', 'unpaid', 'paid'
  String _filter = 'all';
  final Map<String, bool> _selectedEntries = {};
  final Map<String, bool> _selectedExpenses = {};
  String _billedBy = 'James';
  final _notesCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final _clientCompanyCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    _clientNameCtrl.dispose();
    _clientCompanyCtrl.dispose();
    _clientPhoneCtrl.dispose();
    super.dispose();
  }

  void _resetCreate() {
    _creating = false;
    _selectedEntries.clear();
    _selectedExpenses.clear();
    _billedBy = 'James';
    _clientNameCtrl.clear();
    _clientCompanyCtrl.clear();
    _clientPhoneCtrl.clear();
    _notesCtrl.clear();
  }

  String _fmtDateShort(String d) {
    final dt = DateTime.parse('${d}T12:00:00');
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _fmtMoney(double n) {
    return '\$${n.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (_detailId != null) return _buildDetail(provider);
    if (_creating) return _buildCreateFlow(provider);
    return _buildList(provider);
  }

  // ── List ──────────────────────────────────────────────────────────────────

  Widget _buildList(AppProvider provider) {
    final uninvoiced = provider.invoiceableEntries;
    final pendingExpenses = provider.uninvoicedExpenses;
    final allInvoices = [...provider.invoices].reversed.toList();
    final invoices = allInvoices.where((inv) {
      if (_filter == 'paid') return inv.isPaid;
      if (_filter == 'unpaid') return !inv.isPaid;
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Row(
          children: [
            Text('Invoices', style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => setState(() => _creating = true),
              icon: const Icon(Icons.add, size: 16),
              label: Text('New Invoice', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700)),
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
        const SizedBox(height: 12),

        // Filter bar
        Row(
          children: [
            for (final f in [('all', 'All'), ('unpaid', 'Unpaid'), ('paid', 'Paid')]) ...[
              GestureDetector(
                onTap: () => setState(() => _filter = f.$1),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _filter == f.$1 ? AppColors.accent : AppColors.of(context).bgCard,
                    border: Border.all(color: _filter == f.$1 ? AppColors.accent : AppColors.of(context).border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(f.$2,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _filter == f.$1 ? Colors.white : AppColors.of(context).fg2,
                      )),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Uninvoiced banner
        if (uninvoiced.isNotEmpty || pendingExpenses.isNotEmpty) ...[
          GestureDetector(
            onTap: () => setState(() => _creating = true),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(20),
                border: Border.all(color: AppColors.accent.withAlpha(76)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions_outlined, size: 22, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            if (uninvoiced.isNotEmpty) '${uninvoiced.length} uninvoiced ${uninvoiced.length == 1 ? 'entry' : 'entries'}',
                            if (pendingExpenses.isNotEmpty) '${pendingExpenses.length} pending ${pendingExpenses.length == 1 ? 'expense' : 'expenses'}',
                          ].join(' · '),
                          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.of(context).fg),
                        ),
                        Text('Tap to create a new invoice',
                            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.of(context).fg2)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.of(context).fg3, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (invoices.isEmpty)
          const EmptyStateWidget('No invoices yet'),
        if (invoices.isEmpty && allInvoices.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: EmptyStateWidget('No ${_filter} invoices'),
          ),
        ...invoices.map((inv) => _InvoiceCard(
              invoice: inv,
              fmtDate: _fmtDateShort,
              fmtMoney: _fmtMoney,
              onTap: () => setState(() => _detailId = inv.id),
            )),
      ],
    );
  }

  // ── Create flow ───────────────────────────────────────────────────────────

  Widget _buildCreateFlow(AppProvider provider) {
    final uninvoiced = provider.invoiceableEntries;
    final uninvoicedExpenses = provider.uninvoicedExpenses;

    final selectedEntries = uninvoiced.where((e) => _selectedEntries[e.id] == true).toList();
    final selectedExpenses = uninvoicedExpenses.where((e) => _selectedExpenses[e.id] == true).toList();

    final totalHours = selectedEntries.fold(0.0, (a, e) => a + e.hours);
    final totalAmount = selectedEntries.fold(0.0, (a, e) => a + e.hours * provider.getEntryRate(e));
    final expensesTotal = selectedExpenses.fold(0.0, (a, e) => a + e.amount);
    final grandTotal = totalAmount + expensesTotal;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        GestureDetector(
          onTap: () => setState(_resetCreate),
          child: Row(
            children: [
              Icon(Icons.arrow_back, size: 18, color: AppColors.of(context).fg2),
              const SizedBox(width: 4),
              Text('Back', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.of(context).fg2)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('New Invoice', style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
        const SizedBox(height: 16),

        // ── Billed by ──
        Text('BILLED BY',
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.of(context).fg2, letterSpacing: 0.6)),
        const SizedBox(height: 8),
        Row(
          children: ['James', 'Whitney', 'Combined'].map((name) {
            final active = _billedBy == name;
            final isLast = name == 'Combined';
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _billedBy = name),
                child: Container(
                  margin: EdgeInsets.only(right: isLast ? 0 : 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.of(context).bgCard,
                    border: Border.all(color: active ? AppColors.primary : AppColors.of(context).border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(name,
                        style: GoogleFonts.dmSans(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: active ? Colors.white : AppColors.of(context).fg2,
                        )),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // ── Client info ──
        Text('CLIENT INFO (OPTIONAL)',
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.of(context).fg2, letterSpacing: 0.6)),
        const SizedBox(height: 8),
        if (provider.businesses.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...provider.businesses.map((c) => GestureDetector(
                onTap: () => setState(() {
                  _clientNameCtrl.text = c.name ?? '';
                  _clientCompanyCtrl.text = c.company ?? '';
                  _clientPhoneCtrl.text = c.phone ?? '';
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).bgCard,
                    border: Border.all(color: AppColors.of(context).border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline, size: 13, color: AppColors.of(context).fg2),
                      const SizedBox(width: 4),
                      Text(c.displayName,
                          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.of(context).fg)),
                    ],
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: 8),
        ],
        LabeledTextField(label: 'Client Name', controller: _clientNameCtrl, keyboardType: TextInputType.name),
        const SizedBox(height: 8),
        LabeledTextField(label: 'Company', controller: _clientCompanyCtrl),
        const SizedBox(height: 8),
        LabeledTextField(label: 'Phone', controller: _clientPhoneCtrl, keyboardType: TextInputType.phone),
        const SizedBox(height: 20),

        // ── Select entries ──
        Text('SELECT ENTRIES',
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.of(context).fg2, letterSpacing: 0.6)),
        const SizedBox(height: 8),

        if (uninvoiced.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: const EmptyStateWidget('No uninvoiced entries', verticalPadding: 16),
          ),

        ...uninvoiced.map((e) {
          final job = provider.jobs.where((j) => j.id == e.jobId).firstOrNull;
          final rate = provider.getEntryRate(e);
          final isSelected = _selectedEntries[e.id] == true;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedEntries[e.id] = !isSelected),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withAlpha(38) : AppColors.of(context).bgCard,
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.of(context).border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _checkbox(isSelected),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job?.name ?? 'Unknown',
                              style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.of(context).fg),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${_fmtDateShort(e.date)} · ${e.description}',
                              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.of(context).fg2),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    AmountDisplayPair(
                      hoursText: '${e.hours.toStringAsFixed(1)}h',
                      amountText: _fmtMoney(e.hours * rate),
                      hoursSize: 12,
                      amountColor: AppColors.accent,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        // ── Select expenses ──
        const SizedBox(height: 8),
        Text('SELECT EXPENSES (OPTIONAL)',
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.of(context).fg2, letterSpacing: 0.6)),
        const SizedBox(height: 8),

        if (uninvoicedExpenses.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: const EmptyStateWidget('No pending expenses', verticalPadding: 16),
          ),

        ...uninvoicedExpenses.map((e) {
          final isSelected = _selectedExpenses[e.id] == true;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedExpenses[e.id] = !isSelected),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withAlpha(38) : AppColors.of(context).bgCard,
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.of(context).border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _checkbox(isSelected),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.description,
                              style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.of(context).fg),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${e.purchasedBy} · ${_fmtDateShort(e.date)}',
                              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.of(context).fg2)),
                        ],
                      ),
                    ),
                    Text(_fmtMoney(e.amount),
                        style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
                  ],
                ),
              ),
            ),
          );
        }),

        // ── Totals summary ──
        if (selectedEntries.isNotEmpty || selectedExpenses.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(20),
              border: Border.all(color: AppColors.accent.withAlpha(64)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoice Total', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.of(context).fg2)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    MetricItem(label: 'Hours', value: totalHours.toStringAsFixed(1)),
                    const SizedBox(width: 16),
                    MetricItem(label: 'Labour', value: _fmtMoney(totalAmount), color: AppColors.accent),
                    const SizedBox(width: 16),
                    if (expensesTotal > 0)
                      MetricItem(label: 'Parts', value: _fmtMoney(expensesTotal), color: AppColors.accent),
                  ],
                ),
                if (expensesTotal > 0) ...[
                  const SizedBox(height: 8),
                  Container(height: 1, color: AppColors.accent.withAlpha(64)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Grand Total', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
                      Text(_fmtMoney(grandTotal), style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),

        // ── Notes ──
        Text('NOTES (OPTIONAL)',
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.of(context).fg2, letterSpacing: 0.6)),
        const SizedBox(height: 6),
        TextField(
          controller: _notesCtrl,
          maxLines: 2,
          style: GoogleFonts.dmSans(color: AppColors.of(context).fg, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Add a note to this invoice…',
            hintStyle: GoogleFonts.dmSans(color: AppColors.of(context).fg3, fontSize: 13),
            filled: true,
            fillColor: AppColors.of(context).bgCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.of(context).border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.of(context).border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: selectedEntries.isEmpty && selectedExpenses.isEmpty
                ? null
                : () {
                    provider.createInvoice(
                      entryIds: selectedEntries.map((e) => e.id).toList(),
                      expenseIds: selectedExpenses.map((e) => e.id).toList(),
                      totalHours: totalHours,
                      totalAmount: totalAmount,
                      expensesTotal: expensesTotal,
                      notes: _notesCtrl.text.trim(),
                      clientName: _clientNameCtrl.text.trim(),
                      clientCompany: _clientCompanyCtrl.text.trim(),
                      clientPhone: _clientPhoneCtrl.text.trim(),
                      billedBy: _billedBy,
                    );
                    setState(_resetCreate);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: (selectedEntries.isNotEmpty || selectedExpenses.isNotEmpty) ? AppColors.accent : AppColors.of(context).fg3,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('Create Invoice', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  // ── Mark as Paid sheet ────────────────────────────────────────────────────

  Future<void> _showMarkPaidSheet(BuildContext context, AppProvider provider, Invoice inv) async {
    String selectedDate = DateTime.now().toIso8601String().substring(0, 10);
    String? selectedMethod;
    final newMethodCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).bgBase,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          final methods = provider.settings.paymentMethods;
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mark as Paid', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
                const SizedBox(height: 16),
                Text('DATE PAID', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.of(context).fg2, letterSpacing: 0.6)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(primary: AppColors.accent),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setModal(() => selectedDate = picked.toIso8601String().substring(0, 10));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).bgCard,
                      border: Border.all(color: AppColors.of(context).border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.of(context).fg2),
                        const SizedBox(width: 8),
                        Text(selectedDate, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.of(context).fg)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('PAYMENT METHOD', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.of(context).fg2, letterSpacing: 0.6)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...methods.map((m) => GestureDetector(
                      onTap: () => setModal(() => selectedMethod = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selectedMethod == m ? AppColors.accent : AppColors.of(context).bgCard,
                          border: Border.all(color: selectedMethod == m ? AppColors.accent : AppColors.of(context).border),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(m, style: GoogleFonts.dmSans(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: selectedMethod == m ? Colors.white : AppColors.of(context).fg2,
                        )),
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: newMethodCtrl,
                        style: GoogleFonts.dmSans(color: AppColors.of(context).fg, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Add new method…',
                          hintStyle: GoogleFonts.dmSans(color: AppColors.of(context).fg3, fontSize: 13),
                          filled: true,
                          fillColor: AppColors.of(context).bgCard,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.of(context).border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.of(context).border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final v = newMethodCtrl.text.trim();
                        if (v.isEmpty) return;
                        provider.addPaymentMethod(v);
                        setModal(() { selectedMethod = v; newMethodCtrl.clear(); });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text('Add', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedMethod == null ? null : () {
                      provider.markInvoicePaid(inv.id, paidAt: selectedDate, paymentMethod: selectedMethod!);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedMethod != null ? const Color(0xFF16A34A) : AppColors.of(context).fg3,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Confirm Payment', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
    newMethodCtrl.dispose();
  }

  // ── Detail ────────────────────────────────────────────────────────────────

  Widget _buildDetail(AppProvider provider) {
    final inv = provider.invoices.where((i) => i.id == _detailId).firstOrNull;
    if (inv == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _detailId = null));
      return const SizedBox();
    }
    final invEntries = provider.entries.where((e) => inv.entryIds.contains(e.id)).toList();
    final invExpenses = provider.expenses.where((e) => inv.expenseIds.contains(e.id)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        GestureDetector(
          onTap: () => setState(() => _detailId = null),
          child: Row(
            children: [
              Icon(Icons.arrow_back, size: 18, color: AppColors.of(context).fg2),
              const SizedBox(width: 4),
              Text('Back', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.of(context).fg2)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.number, style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Created ${_fmtDateShort(inv.createdAt)}',
                          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.of(context).fg2)),
                      if (inv.billedBy != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(40),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(inv.billedBy!,
                              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            _PdfButton(invoice: inv, provider: provider),
          ],
        ),
        const SizedBox(height: 14),

        // Totals cards
        Row(
          children: [
            Expanded(child: _totalCard('TOTAL HOURS', inv.totalHours.toStringAsFixed(1), AppColors.of(context).fg)),
            const SizedBox(width: 12),
            Expanded(child: _totalCard('LABOUR', _fmtMoney(inv.totalAmount), AppColors.accent, highlight: true)),
          ],
        ),
        if (inv.expensesTotal > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _totalCard('PARTS / EXPENSES', _fmtMoney(inv.expensesTotal), AppColors.accent, highlight: true)),
              const SizedBox(width: 12),
              Expanded(child: _totalCard('GRAND TOTAL', _fmtMoney(inv.totalAmount + inv.expensesTotal), AppColors.accent, highlight: true)),
            ],
          ),
        ],

        if (inv.notes.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Note: ${inv.notes}', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.of(context).fg2, fontStyle: FontStyle.italic)),
        ],

        // Payment status
        const SizedBox(height: 14),
        if (inv.isPaid) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withAlpha(20),
              border: Border.all(color: const Color(0xFF16A34A).withAlpha(76)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paid on ${_fmtDateShort(inv.paidAt!)}',
                          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A))),
                      if (inv.paymentMethod != null)
                        Text(inv.paymentMethod!,
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.of(context).fg2)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => provider.unmarkInvoicePaid(inv.id),
                  child: Text('Undo', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.of(context).fg3)),
                ),
              ],
            ),
          ),
        ] else ...[
          SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showMarkPaidSheet(context, provider, inv),
              icon: const Icon(Icons.payments_outlined, size: 16),
              label: Text('Mark as Paid', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],

        // Client info
        if (inv.clientName != null || inv.clientCompany != null || inv.clientPhone != null) ...[
          const SizedBox(height: 14),
          Text('CLIENT', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.of(context).fg2, letterSpacing: 0.6)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(color: AppColors.of(context).bgCard, border: Border.all(color: AppColors.of(context).border), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (inv.clientName != null) Text(inv.clientName!, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
                if (inv.clientCompany != null) Text(inv.clientCompany!, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.of(context).fg2)),
                if (inv.clientPhone != null) Text(inv.clientPhone!, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.of(context).fg2)),
              ],
            ),
          ),
        ],

        // Entries section
        const SizedBox(height: 16),
        Text('LABOUR ENTRIES (${invEntries.length})',
            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.of(context).fg2, letterSpacing: 0.6)),
        const SizedBox(height: 8),
        ...invEntries.map((e) {
          final job = provider.jobs.where((j) => j.id == e.jobId).firstOrNull;
          final rate = provider.getEntryRate(e);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _detailRow(
              left: job?.name ?? 'Unknown',
              sub: '${_fmtDateShort(e.date)} · ${e.description}',
              right: _fmtMoney(e.hours * rate),
              rightSub: '${e.hours.toStringAsFixed(1)}h',
            ),
          );
        }),

        // Expenses section
        if (invExpenses.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('PARTS & EXPENSES (${invExpenses.length})',
              style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.of(context).fg2, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          ...invExpenses.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _detailRow(
                  left: e.description,
                  sub: '${e.purchasedBy} · ${_fmtDateShort(e.date)}',
                  right: _fmtMoney(e.amount),
                  rightSub: '',
                ),
              )),
        ],

        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            provider.deleteInvoice(inv.id);
            setState(() => _detailId = null);
          },
          icon: const Icon(Icons.delete_outline, size: 15, color: AppColors.danger),
          label: Text('Delete Invoice',
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.danger, width: 0.5),
            backgroundColor: AppColors.danger.withAlpha(25),
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _totalCard(String label, String value, Color valueColor, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: highlight ? AppColors.accent.withAlpha(25) : AppColors.of(context).bgCard,
        border: Border.all(color: highlight ? AppColors.accent.withAlpha(76) : AppColors.of(context).border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: highlight ? AppColors.accent : AppColors.of(context).fg2, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          Text(value, style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }

  Widget _detailRow({required String left, required String sub, required String right, required String rightSub}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.of(context).bgCard,
        border: Border(
          left: BorderSide(color: AppColors.of(context).fg3, width: 4),
          top: BorderSide(color: AppColors.of(context).border),
          right: BorderSide(color: AppColors.of(context).border),
          bottom: BorderSide(color: AppColors.of(context).border),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(left, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
                if (sub.isNotEmpty)
                  Text(sub, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.of(context).fg2)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(right, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
              if (rightSub.isNotEmpty)
                Text(rightSub, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.of(context).fg2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkbox(bool active) => Container(
        width: 20, height: 20,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          border: Border.all(color: active ? AppColors.primary : AppColors.of(context).border, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: active ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
      );
}

// ── PDF Button ────────────────────────────────────────────────────────────────

class _PdfButton extends StatefulWidget {
  final Invoice invoice;
  final AppProvider provider;
  const _PdfButton({required this.invoice, required this.provider});

  @override
  State<_PdfButton> createState() => _PdfButtonState();
}

class _PdfButtonState extends State<_PdfButton> {
  bool _generating = false;

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final p = widget.provider;
      final entries = p.entries.where((e) => widget.invoice.entryIds.contains(e.id)).toList();
      final expenses = p.expenses.where((e) => widget.invoice.expenseIds.contains(e.id)).toList();
      final bytes = await PdfService.buildInvoicePdf(
        invoice: widget.invoice,
        entries: entries,
        jobs: p.jobs,
        settings: p.settings,
        getRate: p.getEntryRate,
        expenses: expenses,
      );
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: '${widget.invoice.number}.pdf');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: _generating ? null : _generate,
        icon: _generating
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.picture_as_pdf_outlined, size: 16),
        label: Text(_generating ? 'Building…' : 'PDF',
            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

// ── Invoice Card ──────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final String Function(String) fmtDate;
  final String Function(double) fmtMoney;
  final VoidCallback onTap;

  const _InvoiceCard({required this.invoice, required this.fmtDate, required this.fmtMoney, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final grandTotal = invoice.totalAmount + invoice.expensesTotal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          decoration: BoxDecoration(
            color: AppColors.of(context).bgCard,
            border: Border.all(color: AppColors.of(context).border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.accent.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.receipt_outlined, size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.number, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.of(context).fg)),
                    Row(
                      children: [
                        Text('${fmtDate(invoice.createdAt)} · ${invoice.entryIds.length} entries',
                            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.of(context).fg2)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: invoice.isPaid
                                ? const Color(0xFF16A34A).withAlpha(30)
                                : AppColors.danger.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(invoice.isPaid ? 'PAID' : 'UNPAID',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: invoice.isPaid ? const Color(0xFF16A34A) : AppColors.danger,
                              )),
                        ),
                        if (invoice.billedBy != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(40),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(invoice.billedBy!,
                                style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fmtMoney(grandTotal),
                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
                  Text('${invoice.totalHours.toStringAsFixed(1)}h',
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.of(context).fg2)),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: AppColors.of(context).fg3, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
