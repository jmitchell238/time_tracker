import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/models/business.dart';

void main() {
  group('Business', () {
    test('toJson serializes all fields', () {
      const b = Business(
        id: 'b1',
        name: 'John Doe',
        company: 'Acme',
        phone: '555-1234',
        address: '123 Main St',
      );
      final j = b.toJson();
      expect(j['id'], 'b1');
      expect(j['name'], 'John Doe');
      expect(j['company'], 'Acme');
      expect(j['phone'], '555-1234');
      expect(j['address'], '123 Main St');
    });

    test('toJson serializes null optional fields', () {
      const b = Business(id: 'b1');
      final j = b.toJson();
      expect(j['name'], isNull);
      expect(j['company'], isNull);
      expect(j['phone'], isNull);
      expect(j['address'], isNull);
    });

    test('fromJson deserializes all fields', () {
      final b = Business.fromJson({
        'id': 'b1',
        'name': 'John Doe',
        'company': 'Acme',
        'phone': '555-1234',
        'address': '123 Main St',
      });
      expect(b.id, 'b1');
      expect(b.name, 'John Doe');
      expect(b.company, 'Acme');
      expect(b.phone, '555-1234');
      expect(b.address, '123 Main St');
    });

    test('fromJson defaults address to null when missing (old json)', () {
      final b = Business.fromJson({'id': 'b1', 'name': 'John Doe'});
      expect(b.address, isNull);
    });

    test('round-trip toJson -> fromJson preserves all fields', () {
      const original = Business(
        id: 'b1',
        name: 'Jane',
        company: 'Widgets Inc',
        phone: '555-9999',
        address: '456 Oak Ave',
      );
      final copy = Business.fromJson(original.toJson());
      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.company, original.company);
      expect(copy.phone, original.phone);
      expect(copy.address, original.address);
    });

    test('displayName prefers company over name', () {
      const b = Business(id: 'b1', name: 'John', company: 'Acme');
      expect(b.displayName, 'Acme');
    });

    test('displayName falls back to name when company is null', () {
      const b = Business(id: 'b1', name: 'John');
      expect(b.displayName, 'John');
    });
  });
}
