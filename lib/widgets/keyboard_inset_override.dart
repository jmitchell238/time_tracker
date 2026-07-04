import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../services/keyboard_inset.dart';

/// Overrides MediaQuery.viewInsets.bottom with the browser-measured keyboard
/// height (see keyboard_inset.dart) so bottom sheets and scaffolds avoid the
/// on-screen keyboard on iOS web, where the platform reports an inset of 0.
///
/// Because the platform never fires a metrics change there, the focused text
/// field would stay hidden even after the padding grows — so when the inset
/// changes we also re-scroll the focused field into view.
class KeyboardInsetOverride extends StatefulWidget {
  final Widget child;
  const KeyboardInsetOverride({super.key, required this.child});

  @override
  State<KeyboardInsetOverride> createState() => _KeyboardInsetOverrideState();
}

class _KeyboardInsetOverrideState extends State<KeyboardInsetOverride> {
  @override
  void initState() {
    super.initState();
    keyboardInset.addListener(_onInsetChanged);
  }

  @override
  void dispose() {
    keyboardInset.removeListener(_onInsetChanged);
    super.dispose();
  }

  void _onInsetChanged() {
    if (keyboardInset.value <= 0) return;
    // Wait for the frame that applies the new padding, then scroll the
    // focused field clear of the keyboard.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final focusContext = FocusManager.instance.primaryFocus?.context;
      if (focusContext == null || !focusContext.mounted) return;
      Scrollable.ensureVisible(
        focusContext,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: const Duration(milliseconds: 150),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: keyboardInset,
      builder: (context, inset, _) {
        final mq = MediaQuery.of(context);
        final bottom = math.max(mq.viewInsets.bottom, inset);
        return MediaQuery(
          data: mq.copyWith(
            viewInsets: mq.viewInsets.copyWith(bottom: bottom),
          ),
          child: widget.child,
        );
      },
    );
  }
}
