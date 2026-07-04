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
}
