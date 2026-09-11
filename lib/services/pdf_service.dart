import 'package:flutter/foundation.dart';
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
const _kPaidGreen = PdfColor.fromInt(0xFF16A34A);

const kDefaultPaymentInstructions = 'Payment accepted by check, cash, or Venmo.';

// Consistent spacing rhythm used throughout the document.
const double _kSp1 = 8;
const double _kSp2 = 12;
const double _kSp3 = 16;
const double _kSp4 = 24;

// Consistent type scale.
const double _kSizeLabel = 8; // uppercase section/meta labels
const double _kSizeBody = 10; // body values, table cells promoted to numbers
const double _kSizeSmall = 8; // muted annotations, footer
const double _kSizeTableHeader = 9; // table header + body cell numbers/text
const double _kSizeTotalLabel = 11; // "TOTAL DUE" label
const double _kSizeTotalDue = 15; // grand total amount
const double _kLabelSpacing = 0.8;

// Shared table border: horizontal rules only, no vertical grid lines.
const pw.TableBorder _kTableRules =
    pw.TableBorder(horizontalInside: pw.BorderSide(color: _kBorder, width: 0.75));

// Content width used to size the totals block relative to the page
// (page width 612 - 2*48 margin = 516).
const double _kContentWidth = 516;

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
    final sortedEntries = [...entries]..sort(_compareEntriesByDate);
    final sortedExpenses = [...expenses]..sort((a, b) => a.date.compareTo(b.date));

    final doc = pw.Document();

    final bold = pw.Font.helveticaBold();
    final regular = pw.Font.helvetica();
    final oblique = pw.Font.helveticaOblique();

    final useCategorized = categories.isNotEmpty &&
        sortedEntries.any((e) => jobs.where((j) => j.id == e.jobId).firstOrNull?.categoryId != null);

    final uniformRate = _isUniformRate(sortedEntries, getRate);
    final double? singleRate =
        uniformRate && sortedEntries.isNotEmpty ? getRate(sortedEntries.first) : null;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
        footer: (ctx) => pw.Container(
          width: double.infinity,
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: _kSp1),
          padding: const pw.EdgeInsets.only(top: _kSp1),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _kBorder, width: 0.5)),
          ),
          child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: pw.TextStyle(font: regular, fontSize: _kSizeSmall, color: _kFg2)),
        ),
        build: (ctx) => [
          _header(invoice, bold, regular),
          pw.SizedBox(height: _kSp4),
          _topSection(invoice, settings, sortedEntries, sortedExpenses, singleRate, bold, regular),
          pw.SizedBox(height: _kSp4),
          if (useCategorized)
            ..._categorizedEntriesSections(
                sortedEntries, jobs, categories, getRate, uniformRate, bold, regular)
          else
            _entriesTable(invoice, sortedEntries, jobs, getRate, uniformRate, bold, regular),
          if (sortedExpenses.isNotEmpty) ...[
            pw.SizedBox(height: _kSp3),
            _expensesSectionHeader(bold, regular),
            pw.SizedBox(height: _kSp1),
            _expensesTable(sortedExpenses, bold, regular),
          ],
          pw.SizedBox(height: _kSp3),
          // The totals block is kept together as one unbreakable unit so it
          // never splits mid-way across a page break. Everything after it
          // (payment instructions, notes, thank-you) flows normally so a
          // page break can land between them instead of stranding the whole
          // closing group on its own page.
          _totalsBlock(invoice, sortedExpenses, bold, regular),
          if (!invoice.isPaid) ...[
            pw.SizedBox(height: _kSp3),
            _paymentInstructionsBlock(settings, bold, regular),
          ],
          if (invoice.notes.isNotEmpty) ...[
            pw.SizedBox(height: _kSp3),
            _notesBlock(invoice, bold, regular, oblique),
          ],
          pw.SizedBox(height: _kSp3),
          pw.Container(
            width: double.infinity,
            alignment: pw.Alignment.center,
            child: pw.Text('Thank you for your business!',
                style: pw.TextStyle(font: oblique, fontSize: _kSizeBody, color: _kFg2)),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // -- Categorized entries ---------------------------------------------------

  static List<pw.Widget> _categorizedEntriesSections(
    List<TimeEntry> entries,
    List<Job> jobs,
    List<EntryCategory> categories,
    double Function(TimeEntry) getRate,
    bool uniformRate,
    pw.Font bold,
    pw.Font regular,
  ) {
    // Group by categoryId on the job
    final Map<String?, List<TimeEntry>> grouped = {};
    for (final e in entries) {
      final job = jobs.where((j) => j.id == e.jobId).firstOrNull;
      grouped.putIfAbsent(job?.categoryId, () => []).add(e);
    }
    for (final list in grouped.values) {
      list.sort(_compareEntriesByDate);
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
        final base = [
          _fmtDateShort(e.date),
          job?.name ?? '-',
          e.description.isEmpty ? '-' : e.description,
          _fmtTimeRange(e),
          e.hours.toStringAsFixed(2),
        ];
        if (!uniformRate) base.add('\$${rate.toStringAsFixed(2)}');
        base.add('\$${(e.hours * rate).toStringAsFixed(2)}');
        return base;
      }).toList();

      widgets.add(pw.TableHelper.fromTextArray(
        headers: uniformRate
            ? ['Date', 'Job', 'Description', 'Time', 'Hours', 'Amount']
            : ['Date', 'Job', 'Description', 'Time', 'Hours', 'Rate', 'Amount'],
        data: rows,
        headerStyle: pw.TextStyle(font: bold, fontSize: _kSizeTableHeader, color: PdfColors.white),
        cellStyle: pw.TextStyle(font: regular, fontSize: _kSizeTableHeader, color: _kFg),
        headerDecoration: pw.BoxDecoration(color: catPdfColor),
        rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
        oddRowDecoration: const pw.BoxDecoration(color: _kBgLight),
        border: _kTableRules,
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        columnWidths: uniformRate
            ? {
                0: const pw.FixedColumnWidth(52),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(4),
                3: const pw.FixedColumnWidth(76),
                4: const pw.FixedColumnWidth(48),
                5: const pw.FixedColumnWidth(56),
              }
            : {
                0: const pw.FixedColumnWidth(52),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FixedColumnWidth(76),
                4: const pw.FixedColumnWidth(48),
                5: const pw.FixedColumnWidth(46),
                6: const pw.FixedColumnWidth(56),
              },
        cellAlignments: uniformRate
            ? {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              }
            : {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
                6: pw.Alignment.centerRight,
              },
      ));

      // Category subtotal row
      widgets.add(pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: _kSp1),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _kBorder, width: 0.75)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('$catName subtotal - ${catHours.toStringAsFixed(2)}h',
                style: pw.TextStyle(font: regular, fontSize: _kSizeTableHeader, color: _kFg2)),
            pw.Text('\$${catAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(font: bold, fontSize: _kSizeTableHeader, color: catPdfColor)),
          ],
        ),
      ));
      widgets.add(pw.SizedBox(height: _kSp2));
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
            pw.Text('Total Labour - ${grandHours.toStringAsFixed(2)}h',
                style: pw.TextStyle(font: bold, fontSize: _kSizeBody, color: _kFg)),
            pw.Text('\$${grandAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(font: bold, fontSize: _kSizeBody, color: _kAccent)),
          ],
        ),
      ));
    }

    return widgets;
  }

  // -- Header ----------------------------------------------------------------

  static pw.Widget _header(Invoice inv, pw.Font bold, pw.Font regular) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const pw.BoxDecoration(color: _kBlue),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('INVOICE',
                  style: pw.TextStyle(
                      font: bold, fontSize: 24, color: PdfColors.white, letterSpacing: 0.5)),
              pw.SizedBox(height: 2),
              pw.Text('Property Work Time Tracker',
                  style: pw.TextStyle(
                      font: regular, fontSize: _kSizeBody, color: _kWhiteMuted)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('INVOICE NUMBER',
                  style: pw.TextStyle(
                      font: bold, fontSize: _kSizeSmall, color: _kWhiteMuted, letterSpacing: _kLabelSpacing)),
              pw.SizedBox(height: 2),
              pw.Text(inv.number,
                  style: pw.TextStyle(
                      font: bold, fontSize: 16, color: _kAccent)),
            ],
          ),
        ],
      ),
    );
  }

  // -- Top section: FROM / BILL TO side by side with meta column ------------

  static pw.Widget _topSection(
    Invoice inv,
    AppSettings settings,
    List<TimeEntry> entries,
    List<ExpenseItem> expenses,
    double? uniformRate,
    pw.Font bold,
    pw.Font regular,
  ) {
    final dueDate = _addDays(_parseDate(inv.createdAt), settings.paymentTermsDays);
    final termsLabel = settings.paymentTermsDays == 0
        ? 'Due on receipt'
        : 'Net ${settings.paymentTermsDays}';
    final servicePeriod = _servicePeriod(entries, expenses);

    final metaRows = <pw.Widget>[
      _metaColumnRow('Invoice Date', _fmtDateLong(inv.createdAt), bold, regular),
      _metaColumnRow('Due Date', _fmtDateLong(_isoDate(dueDate)), bold, regular,
          muted: '($termsLabel)'),
      if (servicePeriod != null) _metaColumnRow('Service Period', servicePeriod, bold, regular),
      if (uniformRate != null)
        _metaColumnRow('Hourly Rate', '\$${uniformRate.toStringAsFixed(2)}', bold, regular),
    ];

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _billingBlock('FROM', [
                _resolveFromName(inv, settings),
                if (settings.billingAddress != null) settings.billingAddress!,
                if (settings.billingPhone != null) settings.billingPhone!,
              ], bold, regular)),
              pw.SizedBox(width: _kSp3),
              pw.Expanded(child: _billingBlock('BILL TO', [
                if (inv.clientName != null) inv.clientName!,
                if (inv.clientCompany != null) inv.clientCompany!,
                if (inv.clientAddress != null) inv.clientAddress!,
                if (inv.clientPhone != null) inv.clientPhone!,
                if (inv.clientName == null && inv.clientCompany == null) '-',
              ], bold, regular)),
            ],
          ),
        ),
        pw.SizedBox(width: _kSp3),
        pw.SizedBox(
          width: 160,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (inv.isPaid) ...[
                _paidStamp(inv, bold, regular),
                pw.SizedBox(height: _kSp2),
              ],
              ...metaRows,
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _metaColumnRow(String label, String value, pw.Font bold, pw.Font regular,
      {String? muted}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: _kSp1),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: bold, fontSize: _kSizeLabel, color: _kFg2, letterSpacing: _kLabelSpacing)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(font: regular, fontSize: _kSizeBody, color: _kFg)),
          if (muted != null)
            pw.Text(muted, style: pw.TextStyle(font: regular, fontSize: _kSizeSmall, color: _kFg2)),
        ],
      ),
    );
  }

  static pw.Widget _paidStamp(Invoice inv, pw.Font bold, pw.Font regular) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE8F8EE),
        border: pw.Border.all(color: _kPaidGreen, width: 1.2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('PAID',
              style: pw.TextStyle(
                  font: bold, fontSize: 14, color: _kPaidGreen, letterSpacing: 1.2)),
          if (inv.paidAt != null) ...[
            pw.SizedBox(height: 2),
            pw.Text('Paid ${_fmtDateLong(inv.paidAt!)}',
                style: pw.TextStyle(font: regular, fontSize: _kSizeSmall, color: _kFg2)),
          ],
          if (inv.paymentMethod != null)
            pw.Text(inv.paymentMethod!,
                style: pw.TextStyle(font: regular, fontSize: _kSizeSmall, color: _kFg2)),
        ],
      ),
    );
  }

  // -- Billing blocks ----------------------------------------------------

  static String _resolveFromName(Invoice inv, AppSettings settings) {
    final full = settings.billingName ?? 'James & Whitney Mitchell';
    final b = inv.billedBy;
    if (b != null && b != 'Combined') {
      final lastName = full.split(' ').last;
      return '$b $lastName';
    }
    return full;
  }

  static pw.Widget _billingBlock(String label, List<String> lines,
      pw.Font bold, pw.Font regular) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(_kSp2),
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
                  fontSize: _kSizeLabel,
                  color: _kFg2,
                  letterSpacing: _kLabelSpacing)),
          pw.SizedBox(height: 6),
          ...lines.map((l) => pw.Text(l,
              style: pw.TextStyle(font: regular, fontSize: _kSizeBody, color: _kFg))),
        ],
      ),
    );
  }

  // -- Line items ------------------------------------------------------------

  static pw.Widget _entriesTable(
    Invoice inv,
    List<TimeEntry> entries,
    List<Job> jobs,
    double Function(TimeEntry) getRate,
    bool uniformRate,
    pw.Font bold,
    pw.Font regular,
  ) {
    final rows = entries.map((e) {
      final job = jobs.where((j) => j.id == e.jobId).firstOrNull;
      final rate = getRate(e);
      final amount = e.hours * rate;
      final base = [
        _fmtDateShort(e.date),
        job?.name ?? '-',
        e.description.isEmpty ? '-' : e.description,
        _fmtTimeRange(e),
        e.hours.toStringAsFixed(2),
      ];
      if (!uniformRate) base.add('\$${rate.toStringAsFixed(2)}');
      base.add('\$${amount.toStringAsFixed(2)}');
      return base;
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: uniformRate
          ? ['Date', 'Job', 'Description', 'Time', 'Hours', 'Amount']
          : ['Date', 'Job', 'Description', 'Time', 'Hours', 'Rate', 'Amount'],
      data: rows,
      headerStyle: pw.TextStyle(font: bold, fontSize: _kSizeTableHeader, color: PdfColors.white),
      cellStyle: pw.TextStyle(font: regular, fontSize: _kSizeTableHeader, color: _kFg),
      headerDecoration: const pw.BoxDecoration(color: _kFg),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: const pw.BoxDecoration(color: _kBgLight),
      border: _kTableRules,
      cellPadding:
          const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      columnWidths: uniformRate
          ? {
              0: const pw.FixedColumnWidth(52),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(4),
              3: const pw.FixedColumnWidth(76),
              4: const pw.FixedColumnWidth(48),
              5: const pw.FixedColumnWidth(56),
            }
          : {
              0: const pw.FixedColumnWidth(52),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FixedColumnWidth(76),
              4: const pw.FixedColumnWidth(48),
              5: const pw.FixedColumnWidth(46),
              6: const pw.FixedColumnWidth(56),
            },
      cellAlignments: uniformRate
          ? {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            }
          : {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
            },
    );
  }

  // -- Expenses section header -----------------------------------------------

  static pw.Widget _expensesSectionHeader(pw.Font bold, pw.Font regular) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: _kSp2, vertical: _kSp1),
      decoration: pw.BoxDecoration(
        color: _kBgLight,
        border: pw.Border.all(color: _kBorder),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('REIMBURSABLE EXPENSES',
              style: pw.TextStyle(
                  font: bold, fontSize: _kSizeLabel, color: _kFg2, letterSpacing: _kLabelSpacing)),
          pw.SizedBox(height: 2),
          pw.Text('Out-of-pocket purchases paid by us - reimbursement requested',
              style: pw.TextStyle(font: regular, fontSize: _kSizeSmall, color: _kFg2)),
        ],
      ),
    );
  }

  // -- Expenses table --------------------------------------------------------

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
      headerStyle: pw.TextStyle(font: bold, fontSize: _kSizeTableHeader, color: PdfColors.white),
      cellStyle: pw.TextStyle(font: regular, fontSize: _kSizeTableHeader, color: _kFg),
      headerDecoration: const pw.BoxDecoration(color: _kFg2),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: const pw.BoxDecoration(color: _kBgLight),
      border: _kTableRules,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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

  // -- Totals ----------------------------------------------------------------

  static pw.Widget _totalsBlock(Invoice inv, List<ExpenseItem> expenses, pw.Font bold, pw.Font regular) {
    final hasExpenses = expenses.isNotEmpty;
    final grandTotal = inv.totalAmount + inv.expensesTotal;
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: _kContentWidth * 0.42,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _kBorder),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            children: [
              _totalRow('Total Hours',
                  inv.totalHours.toStringAsFixed(2), bold, regular),
              pw.Divider(color: _kBorder, height: 1),
              _totalRow('Labour',
                  '\$${inv.totalAmount.toStringAsFixed(2)}', bold, regular),
              if (hasExpenses) ...[
                pw.Divider(color: _kBorder, height: 1),
                _totalRow('Reimbursable Expenses',
                    '\$${inv.expensesTotal.toStringAsFixed(2)}', bold, regular),
              ],
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: _kFg, width: 1.5)),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: _kSp2, vertical: _kSp2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL DUE',
                        style: pw.TextStyle(
                            font: bold, fontSize: _kSizeTotalLabel, color: _kFg, letterSpacing: 0.6)),
                    pw.Text('\$${grandTotal.toStringAsFixed(2)}',
                        style: pw.TextStyle(font: bold, fontSize: _kSizeTotalDue, color: _kAccent)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _totalRow(String label, String value, pw.Font bold, pw.Font regular) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: _kSp2, vertical: _kSp1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(font: regular, fontSize: _kSizeTableHeader, color: _kFg2)),
          pw.Text(value,
              style: pw.TextStyle(font: bold, fontSize: _kSizeTableHeader, color: _kFg)),
        ],
      ),
    );
  }

  // -- Payment instructions -------------------------------------------------

  static pw.Widget _paymentInstructionsBlock(
      AppSettings settings, pw.Font bold, pw.Font regular) {
    final text = (settings.paymentInstructions == null || settings.paymentInstructions!.isEmpty)
        ? kDefaultPaymentInstructions
        : settings.paymentInstructions!;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(_kSp2),
      decoration: pw.BoxDecoration(
        color: _kBgLight,
        border: pw.Border.all(color: _kBorder),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('PAYMENT INSTRUCTIONS',
              style: pw.TextStyle(
                  font: bold, fontSize: _kSizeLabel, color: _kFg2, letterSpacing: _kLabelSpacing)),
          pw.SizedBox(height: 4),
          pw.Text(text, style: pw.TextStyle(font: regular, fontSize: _kSizeBody, color: _kFg)),
        ],
      ),
    );
  }

  // -- Notes -----------------------------------------------------------------

  static pw.Widget _notesBlock(
      Invoice inv, pw.Font bold, pw.Font regular, pw.Font oblique) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(_kSp2),
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
                  font: bold,
                  fontSize: _kSizeLabel,
                  color: _kFg2,
                  letterSpacing: _kLabelSpacing)),
          pw.SizedBox(height: 4),
          pw.Text(inv.notes,
              style:
                  pw.TextStyle(font: oblique, fontSize: _kSizeBody, color: _kFg)),
        ],
      ),
    );
  }

  // -- Helpers ---------------------------------------------------------------

  static int _compareEntriesByDate(TimeEntry a, TimeEntry b) {
    final d = a.date.compareTo(b.date);
    return d != 0 ? d : a.startTime.compareTo(b.startTime);
  }

  static bool _isUniformRate(List<TimeEntry> entries, double Function(TimeEntry) getRate) {
    if (entries.isEmpty) return false;
    final first = getRate(entries.first);
    for (final e in entries) {
      if ((getRate(e) - first).abs() >= 0.005) return false;
    }
    return true;
  }

  @visibleForTesting
  static bool isUniformRate(List<TimeEntry> entries, double Function(TimeEntry) getRate) =>
      _isUniformRate(entries, getRate);

  static DateTime _parseDate(String d) => DateTime.parse('${d}T12:00:00');

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _addDays(DateTime d, int days) => d.add(Duration(days: days));

  @visibleForTesting
  static String dueDateIso(String createdAt, int paymentTermsDays) =>
      _isoDate(_addDays(_parseDate(createdAt), paymentTermsDays));

  @visibleForTesting
  static String paymentTermsLabel(int paymentTermsDays) =>
      paymentTermsDays == 0 ? 'Due on receipt' : 'Net $paymentTermsDays';

  static String? _servicePeriod(List<TimeEntry> entries, List<ExpenseItem> expenses) {
    final dates = <String>[
      ...entries.map((e) => e.date),
      ...expenses.map((e) => e.date),
    ];
    if (dates.isEmpty) return null;
    dates.sort();
    final min = dates.first;
    final max = dates.last;
    if (min == max) return _fmtDateLong(min);
    return '${_fmtDateLong(min)} - ${_fmtDateLong(max)}';
  }

  @visibleForTesting
  static String? servicePeriod(List<TimeEntry> entries, List<ExpenseItem> expenses) =>
      _servicePeriod(entries, expenses);

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

  @visibleForTesting
  static String fmtTimeRange(TimeEntry e) => _fmtTimeRange(e);

  static String _fmtTimeRange(TimeEntry e) {
    if (e.startTime == '00:00' && e.endTime == '00:00') return '-';
    return '${_fmt12(e.startTime)} - ${_fmt12(e.endTime)}';
  }

  static String _fmt12(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $period';
  }
}
