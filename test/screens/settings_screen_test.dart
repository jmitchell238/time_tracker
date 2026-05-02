import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_tracker/models/app_settings.dart';
import 'package:time_tracker/providers/app_provider.dart';
import 'package:time_tracker/screens/settings_screen.dart';
import 'package:time_tracker/services/auth_service.dart';

Future<AppProvider> _provider({double rate = 40.0, String? billingName}) async {
  SharedPreferences.setMockInitialValues({'jobs': '[]', 'entries': '[]', 'invoices': '[]'});
  final p = AppProvider(
      db: FakeFirebaseFirestore(), auth: MockFirebaseAuth(signedIn: true));
  await p.load();
  p.settings = AppSettings(defaultRate: rate, billingName: billingName);
  return p;
}

AuthService _fakeAuth() => AuthService(auth: MockFirebaseAuth());

Widget _wrap(AppProvider p) => ChangeNotifierProvider<AppProvider>.value(
      value: p,
      child: MaterialApp(home: Scaffold(body: SettingsScreen(authService: _fakeAuth()))),
    );

void main() {
  group('SettingsScreen', () {
    testWidgets('renders Settings title', (tester) async {
      final p = await _provider();
      await tester.pumpWidget(_wrap(p));
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('rate field is pre-filled from provider settings', (tester) async {
      final p = await _provider(rate: 40.0);
      await tester.pumpWidget(_wrap(p));
      expect(find.widgetWithText(TextField, '40.00'), findsOneWidget);
    });

    testWidgets('shows James Mitchell in Users section', (tester) async {
      final p = await _provider();
      await tester.pumpWidget(_wrap(p));
      expect(find.text('James Mitchell'), findsOneWidget);
    });

    testWidgets('shows Whitney Mitchell in Users section', (tester) async {
      final p = await _provider();
      await tester.pumpWidget(_wrap(p));
      expect(find.text('Whitney Mitchell'), findsOneWidget);
    });

    testWidgets('shows app info text', (tester) async {
      final p = await _provider();
      await tester.pumpWidget(_wrap(p));
      expect(find.text('Property Work Time Tracker', skipOffstage: false), findsOneWidget);
    });

    testWidgets('shows version info text', (tester) async {
      final p = await _provider();
      await tester.pumpWidget(_wrap(p));
      expect(
        find.text('Version 1.0 · For James & Whitney Mitchell', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('Save Changes button is present', (tester) async {
      final p = await _provider();
      await tester.pumpWidget(_wrap(p));
      expect(find.text('Save Changes', skipOffstage: false), findsOneWidget);
    });

    testWidgets('Log Out button is present', (tester) async {
      final p = await _provider();
      await tester.pumpWidget(_wrap(p));
      expect(find.text('Log Out', skipOffstage: false), findsOneWidget);
    });

    testWidgets('billing Name, Address, Phone labels are present', (tester) async {
      final p = await _provider();
      await tester.pumpWidget(_wrap(p));
      expect(find.text('Name', skipOffstage: false), findsOneWidget);
      expect(find.text('Address', skipOffstage: false), findsOneWidget);
      expect(find.text('Phone', skipOffstage: false), findsOneWidget);
    });

    testWidgets('saving updates defaultRate in provider', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final p = await _provider(rate: 40.0);
      await tester.pumpWidget(_wrap(p));
      final rateField = find.widgetWithText(TextField, '40.00');
      await tester.enterText(rateField, '55.0');
      await tester.pump();
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      expect(p.settings.defaultRate, 55.0);
      await tester.pump(const Duration(seconds: 3)); // drain the _saved reset timer
    });

    testWidgets('Saved! appears after tapping Save Changes', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final p = await _provider();
      await tester.pumpWidget(_wrap(p));
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      expect(find.text('Saved!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3)); // drain the _saved reset timer
    });

    testWidgets('Log Out tapped shows confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final p = await _provider();
      await tester.pumpWidget(_wrap(p));
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure you want to log out?'), findsOneWidget);
    });

    testWidgets('Cancel in logout dialog dismisses without navigating', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final p = await _provider();
      await tester.pumpWidget(_wrap(p));
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('billing name field pre-filled when settings have billingName', (tester) async {
      final p = await _provider(billingName: 'James Mitchell');
      await tester.pumpWidget(_wrap(p));
      expect(find.widgetWithText(TextField, 'James Mitchell', skipOffstage: false), findsOneWidget);
    });
  });
}
