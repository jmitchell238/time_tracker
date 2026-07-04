import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/services/keyboard_inset.dart';
import 'package:time_tracker/widgets/keyboard_inset_override.dart';

void main() {
  tearDown(() => keyboardInset.value = 0);

  Widget harness({EdgeInsets platformInsets = EdgeInsets.zero, required ValueChanged<double> onBottomInset}) {
    return MediaQuery(
      data: MediaQueryData(viewInsets: platformInsets),
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

  testWidgets('passes through zero inset when keyboard is closed', (tester) async {
    double? seen;
    await tester.pumpWidget(harness(onBottomInset: (v) => seen = v));
    expect(seen, 0);
  });

  testWidgets('injects browser-measured keyboard inset into MediaQuery', (tester) async {
    double? seen;
    await tester.pumpWidget(harness(onBottomInset: (v) => seen = v));
    keyboardInset.value = 250;
    await tester.pump();
    expect(seen, 250);
  });

  testWidgets('keeps the larger of platform and measured insets', (tester) async {
    double? seen;
    await tester.pumpWidget(harness(
      platformInsets: const EdgeInsets.only(bottom: 300),
      onBottomInset: (v) => seen = v,
    ));
    keyboardInset.value = 250;
    await tester.pump();
    expect(seen, 300);
  });

  testWidgets('inset clears when keyboard closes', (tester) async {
    double? seen;
    await tester.pumpWidget(harness(onBottomInset: (v) => seen = v));
    keyboardInset.value = 250;
    await tester.pump();
    keyboardInset.value = 0;
    await tester.pump();
    expect(seen, 0);
  });
}
