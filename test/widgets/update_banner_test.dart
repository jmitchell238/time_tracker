import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/services/app_update.dart';
import 'package:time_tracker/widgets/update_banner.dart';

void main() {
  tearDown(() => updateReady.value = false);

  Widget harness() => const MaterialApp(
        home: Scaffold(body: Column(children: [UpdateBanner()])),
      );

  testWidgets('hidden when no update is ready', (tester) async {
    await tester.pumpWidget(harness());
    expect(find.textContaining('New version available'), findsNothing);
  });

  testWidgets('shows banner when an update is ready', (tester) async {
    await tester.pumpWidget(harness());
    updateReady.value = true;
    await tester.pump();
    expect(find.textContaining('New version available'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('hides again when update flag clears', (tester) async {
    await tester.pumpWidget(harness());
    updateReady.value = true;
    await tester.pump();
    updateReady.value = false;
    await tester.pump();
    expect(find.textContaining('New version available'), findsNothing);
  });

  testWidgets('banner shows Updating state after tap', (tester) async {
    await tester.pumpWidget(harness());
    updateReady.value = true;
    await tester.pump();
    await tester.tap(find.textContaining('New version available'));
    await tester.pump();
    expect(find.text('Updating…'), findsOneWidget);
    expect(find.textContaining('New version available'), findsNothing);
  });
}
