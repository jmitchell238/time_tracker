import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/invoice.dart';
import '../theme/app_theme.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  bool _creating = false;
  String? _detailId;
  final Map<String, bool> _selected = {};
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
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

    if (_detailId != null) {
      return _buildDetail(provider);
    }
    if (_creating) {
      return _buildCreateFlow(provider);
    }
    return _buildList(provider);
  }

  Widget _buildList(AppProvider provider) {
    final uninvoiced = provider.uninvoicedEntries;
    final invoices = [...provider.invoices].reversed.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Row(
          children: [
            Text('Invoices', style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.fg)),
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
        const SizedBox(height: 16),

        // Uninvoiced banner
        if (uninvoiced.isNotEmpty) ...[
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
                        Text('${uninvoiced.length} uninvoiced entries',
                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.fg)),
                        Text('Tap to create a new invoice',
                            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.fg2)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.fg3, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Invoice list
        if (invoices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text('No invoices yet', textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.fg3)),
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

  Widget _buildCreateFlow(AppProvider provider) {
    final uninvoiced = provider.uninvoicedEntries;
    final selectedEntries = uninvoiced.where((e) => _selected[e.id] == true).toList();
    final totalHours = selectedEntries.fold(0.0, (a, e) => a + e.hours);
    final totalAmount = selectedEntries.fold(0.0, (a, e) {
      final job = provider.jobs.where((j) => j.id == e.jobId).firstOrNull;
      return a + e.hours * provider.getRate(job);
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        GestureDetector(
          onTap: () => setState(() { _creating = false; _selected.clear(); }),
          child: Row(
            children: [
              const Icon(Icons.arrow_back, size: 18, color: AppColors.fg2),
              const SizedBox(width: 4),
              Text('Back', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.fg2)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('New Invoice', style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.fg)),
        const SizedBox(height: 6),
        Text('Select uninvoiced entries to include:',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.fg2)),
        const SizedBox(height: 14),

        if (uninvoiced.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('No uninvoiced entries', textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.fg3)),
          ),

        ...uninvoiced.map((e) {
          final job = provider.jobs.where((j) => j.id == e.jobId).firstOrNull;
          final rate = provider.getRate(job);
          final isSelected = _selected[e.id] == true;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selected[e.id] = !isSelected),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withAlpha(38) : AppColors.bgCard,
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job?.name ?? 'Unknown',
                              style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.fg),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${_fmtDateShort(e.date)} · ${e.description}',
                              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.fg2),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${e.hours.toStringAsFixed(1)}h',
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.fg)),
                        Text(_fmtMoney(e.hours * rate),
                            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.accent)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        if (selectedEntries.isNotEmpty) ...[
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
                Text('Invoice Total', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.fg2)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _totalItem('Hours', totalHours.toStringAsFixed(1)),
                    const SizedBox(width: 20),
                    _totalItem('Amount', _fmtMoney(totalAmount), color: AppColors.accent),
                    const SizedBox(width: 20),
                    _totalItem('Entries', '${selectedEntries.length}'),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Notes
        Text('NOTES (OPTIONAL)',
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.fg2, letterSpacing: 0.6)),
        const SizedBox(height: 6),
        TextField(
          controller: _notesCtrl,
          maxLines: 2,
          style: GoogleFonts.dmSans(color: AppColors.fg, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Add a note to this invoice…',
            hintStyle: GoogleFonts.dmSans(color: AppColors.fg3, fontSize: 13),
            filled: true,
            fillColor: AppColors.bgCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: selectedEntries.isEmpty ? null : () {
              provider.createInvoice(
                entryIds: selectedEntries.map((e) => e.id).toList(),
                totalHours: totalHours,
                totalAmount: totalAmount,
                notes: _notesCtrl.text.trim(),
              );
              _selected.clear();
              _notesCtrl.clear();
              setState(() => _creating = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedEntries.isNotEmpty ? AppColors.accent : AppColors.fg3,
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

  Widget _buildDetail(AppProvider provider) {
    final inv = provider.invoices.where((i) => i.id == _detailId).firstOrNull;
    if (inv == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _detailId = null));
      return const SizedBox();
    }
    final invEntries = provider.entries.where((e) => inv.entryIds.contains(e.id)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        GestureDetector(
          onTap: () => setState(() => _detailId = null),
          child: Row(
            children: [
              const Icon(Icons.arrow_back, size: 18, color: AppColors.fg2),
              const SizedBox(width: 4),
              Text('Back', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.fg2)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(inv.number, style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.fg)),
        Text('Created ${_fmtDateShort(inv.createdAt)}',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.fg2)),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL HOURS', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.fg2, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    Text('${inv.totalHours.toStringAsFixed(1)}', style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.fg)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(25),
                  border: Border.all(color: AppColors.accent.withAlpha(76)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL AMOUNT', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    Text(_fmtMoney(inv.totalAmount), style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.accent)),
                  ],
                ),
              ),
            ),
          ],
        ),

        if (inv.notes.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Note: ${inv.notes}', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.fg2, fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 16),
        Text('ENTRIES (${invEntries.length})',
            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.fg2, letterSpacing: 0.6)),
        const SizedBox(height: 8),
        ...invEntries.map((e) {
          final job = provider.jobs.where((j) => j.id == e.jobId).firstOrNull;
          final rate = provider.getRate(job);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                border: Border(
                  left: const BorderSide(color: AppColors.fg3, width: 4),
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
                        Text(job?.name ?? 'Unknown',
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.fg)),
                        Text('${_fmtDateShort(e.date)} · ${e.description}',
                            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.fg2)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${e.hours.toStringAsFixed(1)}h',
                          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.fg)),
                      Text(_fmtMoney(e.hours * rate),
                          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.fg2)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _totalItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.fg3, letterSpacing: 0.5)),
        Text(value, style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: color ?? AppColors.fg)),
      ],
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final String Function(String) fmtDate;
  final String Function(double) fmtMoney;
  final VoidCallback onTap;

  const _InvoiceCard({required this.invoice, required this.fmtDate, required this.fmtMoney, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_outlined, size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.number, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.fg)),
                    Text('${fmtDate(invoice.createdAt)} · ${invoice.entryIds.length} entries',
                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.fg2)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fmtMoney(invoice.totalAmount),
                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
                  Text('${invoice.totalHours.toStringAsFixed(1)}h',
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.fg2)),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.fg3, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
