import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/models/invoice.dart';

void main() {
  Invoice makeInvoice({
    String id = 'inv1',
    String number = 'INV-001',
    String createdAt = '2026-04-01',
    String? sentAt,
    List<String> entryIds = const ['e1', 'e2'],
    double totalHours = 8.0,
    double totalAmount = 360.0,
    String notes = 'Net 30',
    String? clientName = 'Acme Corp',
    String? clientCompany = 'Acme',
    String? clientPhone = '555-1234',
  }) =>
      Invoice(
        id: id,
        number: number,
        createdAt: createdAt,
        sentAt: sentAt,
        entryIds: entryIds,
        totalHours: totalHours,
        totalAmount: totalAmount,
        notes: notes,
        clientName: clientName,
        clientCompany: clientCompany,
        clientPhone: clientPhone,
      );

  group('Invoice', () {
    test('toJson serializes all fields', () {
      final inv = makeInvoice(sentAt: '2026-04-05');
      final j = inv.toJson();
      expect(j['id'], 'inv1');
      expect(j['number'], 'INV-001');
      expect(j['createdAt'], '2026-04-01');
      expect(j['sentAt'], '2026-04-05');
      expect(j['entryIds'], ['e1', 'e2']);
      expect(j['totalHours'], 8.0);
      expect(j['totalAmount'], 360.0);
      expect(j['notes'], 'Net 30');
      expect(j['clientName'], 'Acme Corp');
      expect(j['clientCompany'], 'Acme');
      expect(j['clientPhone'], '555-1234');
    });

    test('toJson serializes null optional fields', () {
      final j = makeInvoice(
        sentAt: null,
        clientName: null,
        clientCompany: null,
        clientPhone: null,
      ).toJson();
      expect(j['sentAt'], isNull);
      expect(j['clientName'], isNull);
      expect(j['clientCompany'], isNull);
      expect(j['clientPhone'], isNull);
    });

    test('fromJson deserializes all fields', () {
      final inv = Invoice.fromJson({
        'id': 'inv1',
        'number': 'INV-001',
        'createdAt': '2026-04-01',
        'sentAt': '2026-04-05',
        'entryIds': ['e1', 'e2'],
        'totalHours': 8.0,
        'totalAmount': 360.0,
        'notes': 'Net 30',
        'clientName': 'Acme Corp',
        'clientCompany': 'Acme',
        'clientPhone': '555-1234',
      });
      expect(inv.id, 'inv1');
      expect(inv.number, 'INV-001');
      expect(inv.createdAt, '2026-04-01');
      expect(inv.sentAt, '2026-04-05');
      expect(inv.entryIds, ['e1', 'e2']);
      expect(inv.totalHours, 8.0);
      expect(inv.totalAmount, 360.0);
      expect(inv.notes, 'Net 30');
      expect(inv.clientName, 'Acme Corp');
      expect(inv.clientCompany, 'Acme');
      expect(inv.clientPhone, '555-1234');
    });

    test('fromJson coerces int totalHours and totalAmount to double', () {
      final inv = Invoice.fromJson({
        'id': 'inv1',
        'number': 'INV-001',
        'createdAt': '2026-04-01',
        'entryIds': <String>[],
        'totalHours': 8,
        'totalAmount': 360,
        'notes': '',
      });
      expect(inv.totalHours, 8.0);
      expect(inv.totalHours, isA<double>());
      expect(inv.totalAmount, 360.0);
      expect(inv.totalAmount, isA<double>());
    });

    test('fromJson defaults notes to empty string when missing', () {
      final inv = Invoice.fromJson({
        'id': 'inv1',
        'number': 'INV-001',
        'createdAt': '2026-04-01',
        'entryIds': <String>[],
        'totalHours': 0.0,
        'totalAmount': 0.0,
      });
      expect(inv.notes, '');
    });

    test('fromJson handles null optional fields', () {
      final inv = Invoice.fromJson({
        'id': 'inv1',
        'number': 'INV-001',
        'createdAt': '2026-04-01',
        'sentAt': null,
        'entryIds': <String>[],
        'totalHours': 0.0,
        'totalAmount': 0.0,
        'notes': '',
        'clientName': null,
        'clientCompany': null,
        'clientPhone': null,
      });
      expect(inv.sentAt, isNull);
      expect(inv.clientName, isNull);
      expect(inv.clientCompany, isNull);
      expect(inv.clientPhone, isNull);
    });

    test('fromJson preserves entryIds list', () {
      final inv = Invoice.fromJson({
        'id': 'inv1',
        'number': 'INV-001',
        'createdAt': '2026-04-01',
        'entryIds': ['a', 'b', 'c'],
        'totalHours': 0.0,
        'totalAmount': 0.0,
        'notes': '',
      });
      expect(inv.entryIds, ['a', 'b', 'c']);
    });

    test('round-trip toJson -> fromJson preserves all fields', () {
      final original = makeInvoice(sentAt: '2026-04-05');
      final copy = Invoice.fromJson(original.toJson());
      expect(copy.id, original.id);
      expect(copy.number, original.number);
      expect(copy.createdAt, original.createdAt);
      expect(copy.sentAt, original.sentAt);
      expect(copy.entryIds, original.entryIds);
      expect(copy.totalHours, original.totalHours);
      expect(copy.totalAmount, original.totalAmount);
      expect(copy.notes, original.notes);
      expect(copy.clientName, original.clientName);
      expect(copy.clientCompany, original.clientCompany);
      expect(copy.clientPhone, original.clientPhone);
    });
  });
}
