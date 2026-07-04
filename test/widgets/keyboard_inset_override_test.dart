import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/services/keyboard_inset.dart';
import 'package:time_tracker/widgets/keyboard_inset_override.dart';

void main() {
  tearDown(() => visibleViewportBottom.value = null);

  Widget harness({EdgeInsets platformInsets = EdgeInsets.zero, required ValueChanged<double> onBottomInset}) {
    return MediaQuery(
      data: MediaQueryData(size: const Size(400, 800), viewInsets: platformInsets),
      child: KeyboardInsetOverride(
        child: Builder(
          builder: (context) {
            onBottomInset(MediaQuery.of(context).viewInsets.bottom);
            return const SizedBox();
          },
        ),
      ),
    );
  }

  testWidgets('no override when viewport measurement is unavailable', (tester) async {
    double? seen;
    await tester.pumpWidget(harness(onBottomInset: (v) => seen = v));
    expect(seen, 0);
  });

  testWidgets('injects covered strip below the visual viewport as bottom inset', (tester) async {
    double? seen;
    await tester.pumpWidget(harness(onBottomInset: (v) => seen = v));
    visibleViewportBottom.value = 500; // app is 800 tall → keyboard covers 300
    await tester.pump();
    expect(seen, 300);
  });

  testWidgets('keeps the larger of platform and measured insets', (tester) async {
    double? seen;
    await tester.pumpWidget(harness(
      platformInsets: const EdgeInsets.only(bottom: 400),
      onBottomInset: (v) => seen = v,
    ));
    visibleViewportBottom.value = 500; // measured 300 < platform 400
    await tester.pump();
    expect(seen, 400);
  });

  testWidgets('ignores sub-keyboard-size measurement noise', (tester) async {
    double? seen;
    await tester.pumpWidget(harness(onBottomInset: (v) => seen = v));
    visibleViewportBottom.value = 790; // only 10px covered — browser chrome noise
    await tester.pump();
    expect(seen, 0);
  });

  testWidgets('inset clears when keyboard closes', (tester) async {
    double? seen;
    await tester.pumpWidget(harness(onBottomInset: (v) => seen = v));
    visibleViewportBottom.value = 500;
    await tester.pump();
    visibleViewportBottom.value = 800; // full height visible again
    await tester.pump();
    expect(seen, 0);
  });

  group('iOS standalone estimate fallback', () {
    final originalDetector = isIosWeb;
    tearDown(() => isIosWeb = originalDetector);

    Widget focusHarness(ValueChanged<double> onBottomInset) {
      return MaterialApp(
        builder: (_, child) => KeyboardInsetOverride(child: child!),
        // Probe MediaQuery above the Scaffold: Scaffold consumes the bottom
        // view inset for its body (that's how it resizes for keyboards).
        home: Builder(
          builder: (context) {
            onBottomInset(MediaQuery.of(context).viewInsets.bottom);
            return const Scaffold(body: TextField());
          },
        ),
      );
    }

    testWidgets('applies estimated inset while a text field is focused', (tester) async {
      isIosWeb = () => true;
      double? seen;
      await tester.pumpWidget(focusHarness((v) => seen = v));
      expect(seen, 0);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      final appHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(seen, KeyboardInsetOverride.estimatedInset(appHeight));

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(seen, 0);
    });

    testWidgets('no estimate outside iOS standalone mode', (tester) async {
      isIosWeb = () => false;
      double? seen;
      await tester.pumpWidget(focusHarness((v) => seen = v));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(seen, 0);
    });

    testWidgets('real measurement wins over the estimate', (tester) async {
      isIosWeb = () => true;
      double? seen;
      await tester.pumpWidget(focusHarness((v) => seen = v));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      final appHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      visibleViewportBottom.value = appHeight - 250; // browser reports 250px covered
      await tester.pumpAndSettle();
      expect(seen, 250);
    });
  });
}
