import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/app_settings.dart';
import '../models/entry_category.dart';
import '../models/expense_item.dart';
import '../models/invoice.dart';
import '../models/job.dart';
import '../models/time_entry.dart';

// Brand colours mirrored from AppColors
const _kBlue = PdfColor.fromInt(0xFF2E5C8A);
const _kAccent = PdfColor.fromInt(0xFFF59E0B);
const _kFg = PdfColor.fromInt(0xFF1E293B);
const _kFg2 = PdfColor.fromInt(0xFF475569);
const _kBorder = PdfColor.fromInt(0xFFCBD5E1);
const _kBgLight = PdfColor.fromInt(0xFFF8FAFC);
const _kWhiteMuted = PdfColor(0.85, 0.88, 0.92);

class PdfService {
  static Future<Uint8List> buildInvoicePdf({
    required Invoice invoice,
    required List<TimeEntry> entries,
    required List<Job> jobs,
    required AppSettings settings,
    required double Function(TimeEntry) getRate,
    List<ExpenseItem> expenses = const [],
    List<EntryCategory> categories = const [],
  }) async {
    final doc = pw.Document();

    final bold = pw.Font.helveticaBold();
    final regular = pw.Font.helvetica();
    final oblique = pw.Font.helveticaOblique();

    final useCategorized = categories.isNotEmpty &&
        entries.any((e) => jobs.where((j) => j.id == e.jobId).firstOrNull?.categoryId != null);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
        build: (ctx) => [
          _header(invoice, bold, regular),
          pw.SizedBox(height: 24),
          _billingRow(invoice, settings, bold, regular),
          pw.SizedBox(height: 20),
          if (useCategorized)
            ..._categorizedEntriesSections(entries, jobs, categories, getRate, bold, regular)
          else
            _entriesTable(invoice, entries, jobs, getRate, bold, regular),
          if (expenses.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _expensesSectionHeader(bold, regular),
            pw.SizedBox(height: 6),
            _expensesTable(expenses, bold, regular),
          ],
          pw.SizedBox(height: 16),
          _totalsBlock(invoice, expenses, bold, regular),
          if (invoice.notes.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _notesBlock(invoice, regular, oblique),
          ],
        ],
      ),
    );

    return doc.save();
  }

  // ── Categorized entries ───────────────────────────────────────────────────

  static List<pw.Widget> _categorizedEntriesSections(
    List<TimeEntry> entries,
    List<Job> jobs,
    List<EntryCategory> categories,
    double Function(TimeEntry) getRate,
    pw.Font bold,
    pw.Font regular,
  ) {
    // Group by categoryId on the job
    final Map<String?, List<TimeEntry>> grouped = {};
    for (final e in entries) {
      final job = jobs.where((j) => j.id == e.jobId).firstOrNull;
      grouped.putIfAbsent(job?.categoryId, () => []).add(e);
    }

    // Named categories alphabetically, uncategorized last
    final namedIds = grouped.keys.where((k) => k != null).toList()
      ..sort((a, b) {
        final nameA = categories.where((c) => c.id == a).firstOrNull?.name ?? '';
        final nameB = categories.where((c) => c.id == b).firstOrNull?.name ?? '';
        return nameA.compareTo(nameB);
      });
    final orderedKeys = [...namedIds, if (grouped.containsKey(null)) null];

    final widgets = <pw.Widget>[];
    double grandHours = 0;
    double grandAmount = 0;

    for (final catId in orderedKeys) {
      final catEntries = grouped[catId]!;
      final category = catId != null ? categories.where((c) => c.id == catId).firstOrNull : null;
      final catName = category?.name ?? 'Uncategorized';
      final catPdfColor = category != null ? PdfColor.fromInt(category.colorValue) : _kFg2;

      double catHours = catEntries.fold(0, (a, e) => a + e.hours);
      double catAmount = catEntries.fold(0, (a, e) => a + e.hours * getRate(e));
      grandHours += catHours;
      grandAmount += catAmount;

      // Category section header
      widgets.add(pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: pw.BoxDecoration(
          color: catPdfColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(catName,
            style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white)),
      ));
      widgets.add(pw.SizedBox(height: 4));

      // Entries table for this category
      final rows = catEntries.map((e) {
        final job = jobs.where((j) => j.id == e.jobId).firstOrNull;
        final rate = getRate(e);
        return [
          _fmtDateShort(e.date),
          job?.name ?? '—',
          e.description.isEmpty ? '—' : e.description,
          e.hours.toStringAsFixed(2),
          '\$${rate.toStringAsFixed(2)}',
          '\$${(e.hours * rate).toStringAsFixed(2)}',
        ];
      }).toList();

      widgets.add(pw.TableHelper.fromTextArray(
        headers: ['Date', 'Job', 'Description', 'Hours', 'Rate', 'Amount'],
        data: rows,
        headerStyle: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white),
        cellStyle: pw.TextStyle(font: regular, fontSize: 9, color: _kFg),
        headerDecoration: pw.BoxDecoration(color: catPdfColor),
        rowDecoration: const pw.BoxDecoration(color: _kBgLight),
        oddRowDecoration: const pw.BoxDecoration(color: PdfColors.white),
        border: pw.TableBorder.all(color: _kBorder, width: 0.5),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        columnWidths: {
          0: const pw.FixedColumnWidth(56),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(3),
          3: const pw.FixedColumnWidth(44),
          4: const pw.FixedColumnWidth(52),
          5: const pw.FixedColumnWidth(60),
        },
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.centerLeft,
          3: pw.Alignment.centerRight,
          4: pw.Alignment.centerRight,
          5: pw.Alignment.centerRight,
        },
      ));

      // Category subtotal row
      widgets.add(pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _kBorder, width: 0.5),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('$catName subtotal · ${catHours.toStringAsFixed(2)}h',
                style: pw.TextStyle(font: regular, fontSize: 9, color: _kFg2)),
            pw.Text('\$${catAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(font: bold, fontSize: 9, color: catPdfColor)),
          ],
        ),
      ));
      widgets.add(pw.SizedBox(height: 12));
    }

    // Grand labour total when multiple sections
    if (orderedKeys.length > 1) {
      widgets.add(pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          color: _kBgLight,
          border: pw.Border.all(color: _kBorder),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Total Labour · ${grandHours.toStringAsFixed(2)}h',
                style: pw.TextStyle(font: bold, fontSize: 10, color: _kFg)),
            pw.Text('\$${grandAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(font: bold, fontSize: 10, color: _kAccent)),
          ],
        ),
      ));
    }

    return widgets;
  }

  // ── Header ────────────────────────────────────────────────────────────────

  static pw.Widget _header(Invoice inv, pw.Font bold, pw.Font regular) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(color: _kBlue),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('INVOICE',
                  style: pw.TextStyle(
                      font: bold, fontSize: 22, color: PdfColors.white)),
              pw.SizedBox(height: 2),
              pw.Text('Property Work Time Tracker',
                  style: pw.TextStyle(
                      font: regular, fontSize: 10, color: _kWhiteMuted)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(inv.number,
                  style: pw.TextStyle(
                      font: bold, fontSize: 16, color: _kAccent)),
              pw.SizedBox(height: 4),
              pw.Text(_fmtDateLong(inv.createdAt),
                  style: pw.TextStyle(
                      font: regular, fontSize: 10, color: _kWhiteMuted)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Billing row ───────────────────────────────────────────────────────────

  static String _resolveFromName(Invoice inv, AppSettings settings) {
    final full = settings.billingName ?? 'James & Whitney Mitchell';
    final b = inv.billedBy;
    if (b != null && b != 'Combined') {
      final lastName = full.split(' ').last;
      return '$b $lastName';
    }
    return full;
  }

  static pw.Widget _billingRow(Invoice inv, AppSettings settings,
      pw.Font bold, pw.Font regular) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _billingBlock('FROM', [
          _resolveFromName(inv, settings),
          if (settings.billingAddress != null) settings.billingAddress!,
          if (settings.billingPhone != null) settings.billingPhone!,
        ], bold, regular)),
        pw.SizedBox(width: 24),
        pw.Expanded(child: _billingBlock('BILL TO', [
          if (inv.clientName != null) inv.clientName!,
          if (inv.clientCompany != null) inv.clientCompany!,
          if (inv.clientPhone != null) inv.clientPhone!,
          if (inv.clientName == null && inv.clientCompany == null) '—',
        ], bold, regular)),
      ],
    );
  }

  static pw.Widget _billingBlock(String label, List<String> lines,
      pw.Font bold, pw.Font regular) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _kBgLight,
        border: pw.Border.all(color: _kBorder),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: bold,
                  fontSize: 8,
                  color: _kFg2,
                  letterSpacing: 0.8)),
          pw.SizedBox(height: 6),
          ...lines.map((l) => pw.Text(l,
              style: pw.TextStyle(font: regular, fontSize: 10, color: _kFg))),
        ],
      ),
    );
  }

  // ── Line items ────────────────────────────────────────────────────────────

  static pw.Widget _entriesTable(
    Invoice inv,
    List<TimeEntry> entries,
    List<Job> jobs,
    double Function(TimeEntry) getRate,
    pw.Font bold,
    pw.Font regular,
  ) {
    final rows = entries.map((e) {
      final job = jobs.where((j) => j.id == e.jobId).firstOrNull;
      final rate = getRate(e);
      final amount = e.hours * rate;
      return [
        _fmtDateShort(e.date),
        job?.name ?? '—',
        e.description.isEmpty ? '—' : e.description,
        e.hours.toStringAsFixed(2),
        '\$${rate.toStringAsFixed(2)}',
        '\$${amount.toStringAsFixed(2)}',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Job', 'Description', 'Hours', 'Rate', 'Amount'],
      data: rows,
      headerStyle: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white),
      cellStyle: pw.TextStyle(font: regular, fontSize: 9, color: _kFg),
      headerDecoration: const pw.BoxDecoration(color: _kFg),
      rowDecoration: const pw.BoxDecoration(color: _kBgLight),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      border: pw.TableBorder.all(color: _kBorder, width: 0.5),
      cellPadding:
          const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      columnWidths: {
        0: const pw.FixedColumnWidth(56),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FixedColumnWidth(44),
        4: const pw.FixedColumnWidth(52),
        5: const pw.FixedColumnWidth(60),
      },
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
    );
  }

  // ── Expenses section header ───────────────────────────────────────────────

  static pw.Widget _expensesSectionHeader(pw.Font bold, pw.Font regular) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        color: _kBgLight,
        border: pw.Border.all(color: _kBorder),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('REIMBURSABLE EXPENSES',
              style: pw.TextStyle(font: bold, fontSize: 9, color: _kFg2, letterSpacing: 0.6)),
          pw.SizedBox(height: 2),
          pw.Text('Out-of-pocket purchases paid by us — reimbursement requested',
              style: pw.TextStyle(font: regular, fontSize: 8, color: _kFg2)),
        ],
      ),
    );
  }

  // ── Expenses table ────────────────────────────────────────────────────────

  static pw.Widget _expensesTable(
    List<ExpenseItem> expenses,
    pw.Font bold,
    pw.Font regular,
  ) {
    final rows = expenses.map((e) => [
      _fmtDateShort(e.date),
      e.description,
      e.purchasedBy,
      '\$${e.amount.toStringAsFixed(2)}',
    ]).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Description', 'Purchased By', 'Amount'],
      data: rows,
      headerStyle: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white),
      cellStyle: pw.TextStyle(font: regular, fontSize: 9, color: _kFg),
      headerDecoration: const pw.BoxDecoration(color: _kFg2),
      rowDecoration: const pw.BoxDecoration(color: _kBgLight),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      border: pw.TableBorder.all(color: _kBorder, width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      columnWidths: {
        0: const pw.FixedColumnWidth(56),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(68),
      },
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
      },
    );
  }

  // ── Totals ────────────────────────────────────────────────────────────────

  static pw.Widget _totalsBlock(Invoice inv, List<ExpenseItem> expenses, pw.Font bold, pw.Font regular) {
    final hasExpenses = expenses.isNotEmpty;
    final grandTotal = inv.totalAmount + inv.expensesTotal;
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 220,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _kBorder),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            children: [
              _totalRow('Total Hours',
                  inv.totalHours.toStringAsFixed(2), bold, regular,
                  accent: false),
              pw.Divider(color: _kBorder, height: 1),
              _totalRow('Labour',
                  '\$${inv.totalAmount.toStringAsFixed(2)}', bold, regular,
                  accent: !hasExpenses),
              if (hasExpenses) ...[
                pw.Divider(color: _kBorder, height: 1),
                _totalRow('Reimbursable Expenses',
                    '\$${inv.expensesTotal.toStringAsFixed(2)}', bold, regular,
                    accent: false),
                pw.Divider(color: _kBorder, height: 1),
                _totalRow('Grand Total',
                    '\$${grandTotal.toStringAsFixed(2)}', bold, regular,
                    accent: true),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _totalRow(String label, String value, pw.Font bold,
      pw.Font regular, {required bool accent}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style:
                  pw.TextStyle(font: regular, fontSize: 10, color: _kFg2)),
          pw.Text(value,
              style: pw.TextStyle(
                  font: bold,
                  fontSize: 11,
                  color: accent ? _kAccent : _kFg)),
        ],
      ),
    );
  }

  // ── Notes ─────────────────────────────────────────────────────────────────

  static pw.Widget _notesBlock(
      Invoice inv, pw.Font regular, pw.Font oblique) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _kBgLight,
        border: pw.Border.all(color: _kBorder),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('NOTES',
              style: pw.TextStyle(
                  font: regular,
                  fontSize: 8,
                  color: _kFg2,
                  letterSpacing: 0.8)),
          pw.SizedBox(height: 4),
          pw.Text(inv.notes,
              style:
                  pw.TextStyle(font: oblique, fontSize: 10, color: _kFg)),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _fmtDateShort(String d) {
    final dt = DateTime.parse('${d}T12:00:00');
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}';
  }

  static String _fmtDateLong(String d) {
    final dt = DateTime.parse('${d}T12:00:00');
    const m = ['January','February','March','April','May','June',
                'July','August','September','October','November','December'];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
