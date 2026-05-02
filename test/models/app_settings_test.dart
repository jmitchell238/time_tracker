import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/models/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('default constructor sets defaultRate to 35.0', () {
      const s = AppSettings();
      expect(s.defaultRate, 35.0);
    });

    test('default constructor leaves billing fields null', () {
      const s = AppSettings();
      expect(s.billingName, isNull);
      expect(s.billingAddress, isNull);
      expect(s.billingPhone, isNull);
    });

    test('toJson serializes all fields', () {
      const s = AppSettings(
        defaultRate: 50.0,
        billingName: 'John',
        billingAddress: '123 Main St',
        billingPhone: '555-1234',
      );
      final j = s.toJson();
      expect(j['defaultRate'], 50.0);
      expect(j['billingName'], 'John');
      expect(j['billingAddress'], '123 Main St');
      expect(j['billingPhone'], '555-1234');
    });

    test('toJson serializes null billing fields', () {
      const s = AppSettings(defaultRate: 35.0);
      final j = s.toJson();
      expect(j['billingName'], isNull);
      expect(j['billingAddress'], isNull);
      expect(j['billingPhone'], isNull);
    });

    test('fromJson deserializes all fields', () {
      final s = AppSettings.fromJson({
        'defaultRate': 50.0,
        'billingName': 'John',
        'billingAddress': '123 Main St',
        'billingPhone': '555-1234',
      });
      expect(s.defaultRate, 50.0);
      expect(s.billingName, 'John');
      expect(s.billingAddress, '123 Main St');
      expect(s.billingPhone, '555-1234');
    });

    test('fromJson coerces int defaultRate to double', () {
      final s = AppSettings.fromJson({'defaultRate': 40});
      expect(s.defaultRate, 40.0);
      expect(s.defaultRate, isA<double>());
    });

    test('fromJson uses 35.0 when defaultRate is missing', () {
      final s = AppSettings.fromJson({});
      expect(s.defaultRate, 35.0);
    });

    test('fromJson handles null billing fields', () {
      final s = AppSettings.fromJson({
        'billingName': null,
        'billingAddress': null,
        'billingPhone': null,
      });
      expect(s.billingName, isNull);
      expect(s.billingAddress, isNull);
      expect(s.billingPhone, isNull);
    });

    test('round-trip toJson -> fromJson preserves all fields', () {
      const original = AppSettings(
        defaultRate: 75.0,
        billingName: 'Jane',
        billingAddress: '456 Oak Ave',
        billingPhone: '555-9999',
      );
      final copy = AppSettings.fromJson(original.toJson());
      expect(copy.defaultRate, original.defaultRate);
      expect(copy.billingName, original.billingName);
      expect(copy.billingAddress, original.billingAddress);
      expect(copy.billingPhone, original.billingPhone);
    });

    test('copyWith updates defaultRate', () {
      const s = AppSettings(defaultRate: 35.0);
      final updated = s.copyWith(defaultRate: 60.0);
      expect(updated.defaultRate, 60.0);
    });

    test('copyWith updates billingName', () {
      const s = AppSettings(billingName: 'Old');
      final updated = s.copyWith(billingName: 'New');
      expect(updated.billingName, 'New');
    });

    test('copyWith with clearBillingName sets it to null', () {
      const s = AppSettings(billingName: 'John');
      final updated = s.copyWith(clearBillingName: true);
      expect(updated.billingName, isNull);
    });

    test('copyWith with clearBillingAddress sets it to null', () {
      const s = AppSettings(billingAddress: '123 Main');
      final updated = s.copyWith(clearBillingAddress: true);
      expect(updated.billingAddress, isNull);
    });

    test('copyWith with clearBillingPhone sets it to null', () {
      const s = AppSettings(billingPhone: '555-0000');
      final updated = s.copyWith(clearBillingPhone: true);
      expect(updated.billingPhone, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const s = AppSettings(
        defaultRate: 35.0,
        billingName: 'John',
        billingAddress: '123 Main',
        billingPhone: '555-1234',
      );
      final updated = s.copyWith(defaultRate: 50.0);
      expect(updated.billingName, 'John');
      expect(updated.billingAddress, '123 Main');
      expect(updated.billingPhone, '555-1234');
    });

    // themeMode
    test('default themeMode is system', () {
      const s = AppSettings();
      expect(s.themeMode, 'system');
    });

    test('themeMode can be set to dark', () {
      const s = AppSettings(themeMode: 'dark');
      expect(s.themeMode, 'dark');
    });

    test('themeMode can be set to light', () {
      const s = AppSettings(themeMode: 'light');
      expect(s.themeMode, 'light');
    });

    test('copyWith updates themeMode', () {
      const s = AppSettings(themeMode: 'dark');
      final updated = s.copyWith(themeMode: 'light');
      expect(updated.themeMode, 'light');
    });

    test('copyWith preserves themeMode when not specified', () {
      const s = AppSettings(themeMode: 'dark');
      final updated = s.copyWith(defaultRate: 50.0);
      expect(updated.themeMode, 'dark');
    });

    test('toJson serializes themeMode', () {
      const s = AppSettings(themeMode: 'light');
      expect(s.toJson()['themeMode'], 'light');
    });

    test('fromJson deserializes themeMode', () {
      final s = AppSettings.fromJson({'themeMode': 'light'});
      expect(s.themeMode, 'light');
    });

    test('fromJson defaults themeMode to system when missing', () {
      final s = AppSettings.fromJson({});
      expect(s.themeMode, 'system');
    });

    test('round-trip preserves themeMode', () {
      const s = AppSettings(themeMode: 'dark');
      final copy = AppSettings.fromJson(s.toJson());
      expect(copy.themeMode, 'dark');
    });
  });
}
