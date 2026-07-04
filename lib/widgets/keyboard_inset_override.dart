import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../services/analytics_service.dart';
import '../services/keyboard_inset.dart';

/// Overrides MediaQuery.viewInsets.bottom with the keyboard overlap measured
/// from the browser's visualViewport (see keyboard_inset.dart), so bottom
/// sheets and scaffolds avoid the on-screen keyboard on iOS web, where the
/// platform reports an inset of 0.
///
/// The overlap is the app's own rendered height minus the visual viewport's
/// bottom edge: whatever part of the Flutter canvas the browser says is not
/// visible. Measuring against the canvas (not window.innerHeight) stays
/// correct whether or not the browser shrinks the page for the keyboard.
///
/// Because the platform never fires a metrics change here, the focused text
/// field would stay hidden even after the padding grows — so when the
/// measurement changes we also re-scroll the focused field into view.
class KeyboardInsetOverride extends StatefulWidget {
  final Widget child;
  const KeyboardInsetOverride({super.key, required this.child});

  /// Overlaps smaller than this are browser-chrome measurement noise, not a
  /// keyboard (mobile keyboards are 200+ logical px tall).
  static const double _minKeyboardPx = 60;

  static double measuredInset(double appHeight, double? visibleBottom) {
    if (visibleBottom == null) return 0;
    final covered = appHeight - visibleBottom;
    return covered < _minKeyboardPx ? 0 : covered;
  }

  @override
  State<KeyboardInsetOverride> createState() => _KeyboardInsetOverrideState();
}

class _KeyboardInsetOverrideState extends State<KeyboardInsetOverride> {
  static int _diagnosticsLogged = 0;

  @override
  void initState() {
    super.initState();
    visibleViewportBottom.addListener(_onViewportChanged);
  }

  @override
  void dispose() {
    visibleViewportBottom.removeListener(_onViewportChanged);
    super.dispose();
  }

  void _onViewportChanged() {
    // Wait for the frame that applies the new padding, then scroll the
    // focused field clear of the keyboard.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_diagnosticsLogged < 15) {
        _diagnosticsLogged++;
        Analytics.capture('keyboard_viewport_measured', properties: {
          'visible_bottom': visibleViewportBottom.value ?? -1,
          'app_height': MediaQuery.of(context).size.height,
        });
      }
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
    return ValueListenableBuilder<double?>(
      valueListenable: visibleViewportBottom,
      builder: (context, visibleBottom, _) {
        final mq = MediaQuery.of(context);
        final measured =
            KeyboardInsetOverride.measuredInset(mq.size.height, visibleBottom);
        final bottom = math.max(mq.viewInsets.bottom, measured);
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
