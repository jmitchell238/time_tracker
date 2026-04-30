import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/invoice.dart';
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
  final Map<String, bool> _selected = {};
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
    final uninvoiced = provider.invoiceableEntries;
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
          const EmptyStateWidget('No invoices yet'),
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
    final uninvoiced = provider.invoiceableEntries;
    final selectedEntries = uninvoiced.where((e) => _selected[e.id] == true).toList();
    final totalHours = selectedEntries.fold(0.0, (a, e) => a + e.hours);
    final totalAmount = selectedEntries.fold(0.0, (a, e) {
      return a + e.hours * provider.getEntryRate(e);
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _creating = false;
            _selected.clear();
            _clientNameCtrl.clear();
            _clientCompanyCtrl.clear();
            _clientPhoneCtrl.clear();
          }),
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
        const SizedBox(height: 16),

        // Client info
        Text('CLIENT INFO (OPTIONAL)',
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.fg2, letterSpacing: 0.6)),
        const SizedBox(height: 8),
        LabeledTextField(label: 'Client Name', controller: _clientNameCtrl, keyboardType: TextInputType.name),
        const SizedBox(height: 8),
        LabeledTextField(label: 'Company', controller: _clientCompanyCtrl),
        const SizedBox(height: 8),
        LabeledTextField(label: 'Phone', controller: _clientPhoneCtrl, keyboardType: TextInputType.phone),
        const SizedBox(height: 16),

        Text('SELECT ENTRIES',
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.fg2, letterSpacing: 0.6)),
        const SizedBox(height: 8),

        if (uninvoiced.isEmpty)
          const EmptyStateWidget('No uninvoiced entries', verticalPadding: 24),

        ...uninvoiced.map((e) {
          final job = provider.jobs.where((j) => j.id == e.jobId).firstOrNull;
          final rate = provider.getEntryRate(e);
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
                    MetricItem(label: 'Hours', value: totalHours.toStringAsFixed(1)),
                    const SizedBox(width: 20),
                    MetricItem(label: 'Amount', value: _fmtMoney(totalAmount), color: AppColors.accent),
                    const SizedBox(width: 20),
                    MetricItem(label: 'Entries', value: '${selectedEntries.length}'),
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
                clientName: _clientNameCtrl.text.trim(),
                clientCompany: _clientCompanyCtrl.text.trim(),
                clientPhone: _clientPhoneCtrl.text.trim(),
              );
              _selected.clear();
              _notesCtrl.clear();
              _clientNameCtrl.clear();
              _clientCompanyCtrl.clear();
              _clientPhoneCtrl.clear();
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
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.number, style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.fg)),
                  Text('Created ${_fmtDateShort(inv.createdAt)}',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.fg2)),
                ],
              ),
            ),
            _PdfButton(invoice: inv, provider: provider),
          ],
        ),
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
                    Text(inv.totalHours.toStringAsFixed(1), style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.fg)),
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

        // Client info
        if (inv.clientName != null || inv.clientCompany != null || inv.clientPhone != null) ...[
          const SizedBox(height: 14),
          Text('CLIENT', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.fg2, letterSpacing: 0.6)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (inv.clientName != null)
                  Text(inv.clientName!, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.fg)),
                if (inv.clientCompany != null)
                  Text(inv.clientCompany!, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.fg2)),
                if (inv.clientPhone != null)
                  Text(inv.clientPhone!, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.fg2)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text('ENTRIES (${invEntries.length})',
            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.fg2, letterSpacing: 0.6)),
        const SizedBox(height: 8),
        ...invEntries.map((e) {
          final job = provider.jobs.where((j) => j.id == e.jobId).firstOrNull;
          final rate = provider.getEntryRate(e);
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
                  AmountDisplayPair(
                    hoursText: '${e.hours.toStringAsFixed(1)}h',
                    amountText: _fmtMoney(e.hours * rate),
                    hoursSize: 12,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

}

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
      final entries = p.entries
          .where((e) => widget.invoice.entryIds.contains(e.id))
          .toList();
      final bytes = await PdfService.buildInvoicePdf(
        invoice: widget.invoice,
        entries: entries,
        jobs: p.jobs,
        settings: p.settings,
        getRate: p.getEntryRate,
      );
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: '${widget.invoice.number}.pdf',
      );
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
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
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
