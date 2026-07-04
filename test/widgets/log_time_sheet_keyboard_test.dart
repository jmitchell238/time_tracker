import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_tracker/models/job.dart';
import 'package:time_tracker/providers/app_provider.dart';
import 'package:time_tracker/services/keyboard_inset.dart';
import 'package:time_tracker/widgets/keyboard_inset_override.dart';
import 'package:time_tracker/widgets/log_time_sheet.dart';

Future<AppProvider> _provider() async {
  SharedPreferences.setMockInitialValues({'jobs': '[]', 'entries': '[]', 'invoices': '[]'});
  final p = AppProvider(db: FakeFirebaseFirestore(), auth: MockFirebaseAuth(signedIn: true));
  await p.load();
  p.jobs = [
    Job(id: 'j1', name: 'Lawn', description: '', rate: 45.0, isArchived: false, createdAt: DateTime(2026)),
  ];
  return p;
}

void main() {
  tearDown(() => visibleViewportBottom.value = null);

  testWidgets('description field in the Log Time modal moves above a keyboard reported through the inset override', (tester) async {
    // Phone-sized surface (iPhone-ish logical dimensions).
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final p = await _provider();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: p,
        child: MaterialApp(
          builder: (_, child) => KeyboardInsetOverride(child: child!),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => LogTimeSheet.show(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Log Time'), findsOneWidget);

    // Focus the description field, then simulate a 350px keyboard the way
    // the browser reports it (visual viewport bottom edge moves up).
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    const keyboardTop = 844.0 - 350.0;
    visibleViewportBottom.value = keyboardTop;
    await tester.pumpAndSettle();

    final fieldRect = tester.getRect(find.byType(TextField));
    expect(
      fieldRect.bottom,
      lessThanOrEqualTo(keyboardTop + 1),
      reason: 'description field should sit above the keyboard '
          '(field bottom ${fieldRect.bottom}, keyboard top $keyboardTop)',
    );
  });

  testWidgets('description field moves above the estimated keyboard on iOS web with no measurement', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final originalDetector = isIosWeb;
    isIosWeb = () => true;
    addTearDown(() => isIosWeb = originalDetector);

    final p = await _provider();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: p,
        child: MaterialApp(
          builder: (_, child) => KeyboardInsetOverride(child: child!),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => LogTimeSheet.show(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Focusing the field is the only signal iOS gives us — no viewport
    // measurement is simulated here on purpose.
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final keyboardTop = 844.0 - KeyboardInsetOverride.estimatedInset(844.0);
    final fieldRect = tester.getRect(find.byType(TextField));
    expect(
      fieldRect.bottom,
      lessThanOrEqualTo(keyboardTop + 1),
      reason: 'description field should sit above the estimated keyboard '
          '(field bottom ${fieldRect.bottom}, keyboard top $keyboardTop)',
    );
  });
}
