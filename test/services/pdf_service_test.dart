import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/models/app_settings.dart';
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
    );

TimeEntry _entry({
  String id = 'e1',
  String jobId = 'j1',
  double hours = 8.0,
  double? rateOverride,
}) =>
    TimeEntry(
      id: id,
      jobId: jobId,
      date: '2026-04-01',
      startTime: '09:00',
      endTime: '17:00',
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
}
