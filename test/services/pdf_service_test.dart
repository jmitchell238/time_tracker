import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/models/app_settings.dart';
import 'package:time_tracker/models/expense_item.dart';
import 'package:time_tracker/models/invoice.dart';
import 'package:time_tracker/models/job.dart';
import 'package:time_tracker/models/time_entry.dart';
import 'package:time_tracker/services/pdf_service.dart';

Invoice _invoice({
  String notes = '',
  String? clientName = 'Acme Corp',
  String? clientCompany = 'Acme',
  String? clientPhone = '555-1234',
  String? sentAt,
  String? billedBy,
  List<String> entryIds = const ['e1'],
}) =>
    Invoice(
      id: 'inv1',
      number: 'INV-001',
      createdAt: '2026-04-01',
      sentAt: sentAt,
      entryIds: entryIds,
      totalHours: 8.0,
      totalAmount: 360.0,
      notes: notes,
      clientName: clientName,
      clientCompany: clientCompany,
      clientPhone: clientPhone,
      billedBy: billedBy,
    );

TimeEntry _entry({
  String id = 'e1',
  String jobId = 'j1',
  double hours = 8.0,
  double? rateOverride,
  String startTime = '09:00',
  String endTime = '17:00',
}) =>
    TimeEntry(
      id: id,
      jobId: jobId,
      date: '2026-04-01',
      startTime: startTime,
      endTime: endTime,
      hours: hours,
      description: 'Test work',
      rateOverride: rateOverride,
    );

Job _job({String id = 'j1', double? rate = 45.0}) => Job(
      id: id,
      name: 'Lawn Care',
      description: '',
      rate: rate,
      isArchived: false,
      createdAt: DateTime(2026),
    );

const _settings = AppSettings(defaultRate: 35.0, billingName: 'John Doe');

double _rate(TimeEntry e) => e.rateOverride ?? 45.0;

void main() {
  group('PdfService.buildInvoicePdf', () {
    test('returns non-empty Uint8List', () async {
      final bytes = await PdfService.buildInvoicePdf(
        invoice: _invoice(),
        entries: [_entry()],
        jobs: [_job()],
        settings: _settings,
        getRate: _rate,
      );
      expect(bytes, isNotEmpty);
    });

    test('output starts with PDF magic bytes', () async {
      final bytes = await PdfService.buildInvoicePdf(
        invoice: _invoice(),
        entries: [_entry()],
        jobs: [_job()],
        settings: _settings,
        getRate: _rate,
      );
      // PDF files always begin with %PDF
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, startsWith('%PDF'));
    });

    test('completes without error for minimal invoice (all nullables null)', () async {
      final bytes = await PdfService.buildInvoicePdf(
        invoice: _invoice(
          clientName: null,
          clientCompany: null,
          clientPhone: null,
          sentAt: null,
        ),
        entries: [_entry()],
        jobs: [_job()],
        settings: const AppSettings(),
        getRate: _rate,
      );
      expect(bytes, isNotEmpty);
    });

    test('completes without error when entries list is empty', () async {
      final bytes = await PdfService.buildInvoicePdf(
        invoice: _invoice(entryIds: []),
        entries: [],
        jobs: [_job()],
        settings: _settings,
        getRate: _rate,
      );
      expect(bytes, isNotEmpty);
    });

    test('completes without error when notes is empty (notes block omitted)', () async {
      final bytes = await PdfService.buildInvoicePdf(
        invoice: _invoice(notes: ''),
        entries: [_entry()],
        jobs: [_job()],
        settings: _settings,
        getRate: _rate,
      );
      expect(bytes, isNotEmpty);
    });

    test('completes without error when notes is non-empty (notes block included)', () async {
      final bytes = await PdfService.buildInvoicePdf(
        invoice: _invoice(notes: 'Net 30'),
        entries: [_entry()],
        jobs: [_job()],
        settings: _settings,
        getRate: _rate,
      );
      expect(bytes, isNotEmpty);
    });

    test('completes without error when job not found for entry', () async {
      final bytes = await PdfService.buildInvoicePdf(
        invoice: _invoice(),
        entries: [_entry(jobId: 'unknown')],
        jobs: [],
        settings: _settings,
        getRate: _rate,
      );
      expect(bytes, isNotEmpty);
    });

    test('completes without error when entry has rateOverride', () async {
      final bytes = await PdfService.buildInvoicePdf(
        invoice: _invoice(),
        entries: [_entry(rateOverride: 60.0)],
        jobs: [_job()],
        settings: _settings,
        getRate: (e) => e.rateOverride ?? 45.0,
      );
      expect(bytes, isNotEmpty);
    });

    test('completes without error for multiple entries', () async {
      final bytes = await PdfService.buildInvoicePdf(
        invoice: _invoice(entryIds: ['e1', 'e2', 'e3']),
        entries: [
          _entry(id: 'e1', hours: 2.0),
          _entry(id: 'e2', hours: 3.5),
          _entry(id: 'e3', hours: 1.0),
        ],
        jobs: [_job()],
        settings: _settings,
        getRate: _rate,
      );
      expect(bytes, isNotEmpty);
    });

  });

  group('PdfService.fmtTimeRange', () {
    test('formats a normal entry as a 12-hour AM/PM range', () {
      final e = _entry(startTime: '08:00', endTime: '14:30');
      expect(PdfService.fmtTimeRange(e), '8:00 AM - 2:30 PM');
    });

    test('midnight (00:00) formats as 12:00 AM', () {
      final e = _entry(startTime: '00:00', endTime: '01:00');
      expect(PdfService.fmtTimeRange(e), '12:00 AM - 1:00 AM');
    });

    test('noon (12:00) formats as 12:00 PM', () {
      final e = _entry(startTime: '11:00', endTime: '12:00');
      expect(PdfService.fmtTimeRange(e), '11:00 AM - 12:00 PM');
    });

    test('13:05 formats as 1:05 PM', () {
      final e = _entry(startTime: '13:05', endTime: '13:30');
      expect(PdfService.fmtTimeRange(e), '1:05 PM - 1:30 PM');
    });

    test('both times 00:00 renders a hyphen instead of a fake range', () {
      final e = _entry(startTime: '00:00', endTime: '00:00');
      expect(PdfService.fmtTimeRange(e), '-');
    });
  });

  group('PdfService.isUniformRate', () {
    test('returns false for an empty entry list', () {
      expect(PdfService.isUniformRate([], (_) => 45.0), isFalse);
    });

    test('returns true for a single entry', () {
      expect(PdfService.isUniformRate([_entry()], (_) => 45.0), isTrue);
    });

    test('returns true when all entries share the same rate', () {
      final entries = [_entry(id: 'e1'), _entry(id: 'e2'), _entry(id: 'e3')];
      expect(PdfService.isUniformRate(entries, (_) => 45.0), isTrue);
    });

    test('returns false when rates differ', () {
      final entries = [
        _entry(id: 'e1', rateOverride: 45.0),
        _entry(id: 'e2', rateOverride: 60.0),
      ];
      expect(PdfService.isUniformRate(entries, (e) => e.rateOverride ?? 45.0), isFalse);
    });

    test('treats rates within epsilon as uniform', () {
      final entries = [
        _entry(id: 'e1', rateOverride: 45.000),
        _entry(id: 'e2', rateOverride: 45.001),
      ];
      expect(PdfService.isUniformRate(entries, (e) => e.rateOverride ?? 45.0), isTrue);
    });
  });

  group('PdfService.servicePeriod', () {
    TimeEntry entryOn(String id, String date) => TimeEntry(
          id: id,
          jobId: 'j1',
          date: date,
          startTime: '09:00',
          endTime: '17:00',
          hours: 8.0,
          description: '',
        );

    test('returns null when there are no dated items', () {
      expect(PdfService.servicePeriod([], []), isNull);
    });

    test('returns a single formatted date when min equals max', () {
      final entries = [entryOn('e1', '2026-07-10')];
      expect(PdfService.servicePeriod(entries, []), 'July 10, 2026');
    });

    test('returns a formatted range for multiple dates', () {
      final entries = [entryOn('e1', '2026-07-10'), entryOn('e2', '2026-09-10')];
      expect(PdfService.servicePeriod(entries, []), 'July 10, 2026 - September 10, 2026');
    });

    test('includes expense dates outside the entry date range', () {
      final entries = [entryOn('e1', '2026-07-10')];
      final expenses = [
        ExpenseItem(id: 'x1', description: 'Supplies', amount: 10, date: '2026-08-01', purchasedBy: 'James'),
      ];
      expect(PdfService.servicePeriod(entries, expenses), 'July 10, 2026 - August 1, 2026');
    });
  });

  group('PdfService due date computation', () {
    test('dueDateIso adds paymentTermsDays to the invoice date', () {
      expect(PdfService.dueDateIso('2026-04-01', 14), '2026-04-15');
    });

    test('dueDateIso handles 0 days (due on receipt date)', () {
      expect(PdfService.dueDateIso('2026-04-01', 0), '2026-04-01');
    });

    test('paymentTermsLabel returns Due on receipt for 0 days', () {
      expect(PdfService.paymentTermsLabel(0), 'Due on receipt');
    });

    test('paymentTermsLabel returns Net N for nonzero days', () {
      expect(PdfService.paymentTermsLabel(14), 'Net 14');
      expect(PdfService.paymentTermsLabel(30), 'Net 30');
    });
  });

  group('PdfService.buildInvoicePdf uniform vs varying rates', () {
    test('completes without error when all entries share the same rate', () async {
      final bytes = await PdfService.buildInvoicePdf(
        invoice: _invoice(entryIds: ['e1', 'e2']),
        entries: [
          _entry(id: 'e1', rateOverride: 45.0),
          _entry(id: 'e2', rateOverride: 45.0),
        ],
        jobs: [_job()],
        settings: _settings,
        getRate: (e) => e.rateOverride ?? 45.0,
      );
      expect(bytes, isNotEmpty);
    });

    test('completes without error when entries have differing rates', () async {
      final bytes = await PdfService.buildInvoicePdf(
        invoice: _invoice(entryIds: ['e1', 'e2']),
        entries: [
          _entry(id: 'e1', rateOverride: 45.0),
          _entry(id: 'e2', rateOverride: 60.0),
        ],
        jobs: [_job()],
        settings: _settings,
        getRate: (e) => e.rateOverride ?? 45.0,
      );
      expect(bytes, isNotEmpty);
    });

    test('completes without error for a paid invoice', () async {
      final bytes = await PdfService.buildInvoicePdf(
        invoice: Invoice(
          id: 'inv1',
          number: 'INV-001',
          createdAt: '2026-04-01',
          entryIds: const ['e1'],
          totalHours: 8.0,
          totalAmount: 360.0,
          notes: '',
          paidAt: '2026-04-10',
          paymentMethod: 'Venmo',
        ),
        entries: [_entry()],
        jobs: [_job()],
        settings: _settings,
        getRate: _rate,
      );
      expect(bytes, isNotEmpty);
    });

    test('completes without error with custom payment terms and instructions', () async {
      final bytes = await PdfService.buildInvoicePdf(
        invoice: _invoice(),
        entries: [_entry()],
        jobs: [_job()],
        settings: const AppSettings(paymentTermsDays: 0, paymentInstructions: 'Wire only.'),
        getRate: _rate,
      );
      expect(bytes, isNotEmpty);
    });

    test('completes without error with expenses and a client address', () async {
      final bytes = await PdfService.buildInvoicePdf(
        invoice: Invoice(
          id: 'inv1',
          number: 'INV-001',
          createdAt: '2026-04-01',
          entryIds: const ['e1'],
          expenseIds: const ['x1'],
          totalHours: 8.0,
          totalAmount: 360.0,
          expensesTotal: 10.0,
          notes: '',
          clientAddress: '123 Main St',
        ),
        entries: [_entry()],
        expenses: [
          ExpenseItem(id: 'x1', description: 'Supplies', amount: 10, date: '2026-04-01', purchasedBy: 'James'),
        ],
        jobs: [_job()],
        settings: _settings,
        getRate: _rate,
      );
      expect(bytes, isNotEmpty);
    });
  });

  group('PdfService.invoiceFileName', () {
    test('joins person, business, and mm-dd-yyyy date', () {
      final inv = _invoice(clientName: 'Josh Duke', clientCompany: '1819 The Restaurant');
      const settings = AppSettings(billingName: 'James & Whitney Mitchell');
      expect(
        PdfService.invoiceFileName(inv, settings),
        'james-whitney-mitchell-1819-the-restaurant-invoice-04-01-2026.pdf',
      );
    });

    test('uses the billedBy person when the invoice names one', () {
      final inv = _invoice(clientCompany: '1819 The Restaurant', billedBy: 'Whitney');
      const settings = AppSettings(billingName: 'James & Whitney Mitchell');
      expect(
        PdfService.invoiceFileName(inv, settings),
        'whitney-mitchell-1819-the-restaurant-invoice-04-01-2026.pdf',
      );
    });

    test('falls back to the client name when there is no company', () {
      final inv = _invoice(clientName: 'Josh Duke', clientCompany: null, billedBy: 'Whitney');
      const settings = AppSettings(billingName: 'Whitney Mitchell');
      expect(
        PdfService.invoiceFileName(inv, settings),
        'whitney-mitchell-josh-duke-invoice-04-01-2026.pdf',
      );
    });

    test('omits the business segment entirely when no client is set', () {
      final inv = _invoice(clientName: null, clientCompany: null, billedBy: 'Whitney');
      const settings = AppSettings(billingName: 'Whitney Mitchell');
      expect(
        PdfService.invoiceFileName(inv, settings),
        'whitney-mitchell-invoice-04-01-2026.pdf',
      );
    });
  });
}
