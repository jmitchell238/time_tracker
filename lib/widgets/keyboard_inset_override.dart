import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../services/analytics_service.dart';
import '../services/keyboard_inset.dart';

/// Overrides MediaQuery.viewInsets.bottom with the on-screen keyboard overlap
/// on web, where the platform reports an inset of 0 and fields end up hidden
/// behind the keyboard.
///
/// Two sources, best wins:
/// 1. Measured — the app's own rendered height minus the visualViewport's
///    bottom edge (see keyboard_inset.dart). Correct wherever the browser
///    actually reports the keyboard.
/// 2. Estimated — iOS home-screen web apps report NO viewport change at all
///    when the keyboard opens (WebKit bug), so when a text field is focused
///    there and nothing was measured, we assume a typical keyboard height.
///    Overestimating just scrolls the field slightly higher, so the estimate
///    is deliberately generous.
///
/// Because the platform never fires a metrics change here, the focused field
/// would stay hidden even after the padding grows — so on focus and viewport
/// changes we also re-scroll the focused field into view.
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

  /// Portrait iPhone keyboards (with the suggestion/accessory bar) run
  /// roughly 40–48% of screen height depending on model.
  static double estimatedInset(double appHeight) =>
      (appHeight * 0.45).clamp(320.0, 480.0);

  @override
  State<KeyboardInsetOverride> createState() => _KeyboardInsetOverrideState();
}

class _KeyboardInsetOverrideState extends State<KeyboardInsetOverride> {
  static int _diagnosticsLogged = 0;

  bool _textFieldFocused = false;

  @override
  void initState() {
    super.initState();
    visibleViewportBottom.addListener(_onViewportChanged);
    FocusManager.instance.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    visibleViewportBottom.removeListener(_onViewportChanged);
    FocusManager.instance.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    final focused = focusContext != null &&
        focusContext.findAncestorStateOfType<EditableTextState>() != null;
    if (focused == _textFieldFocused) return;
    setState(() => _textFieldFocused = focused);
    if (focused) _scrollFocusedFieldIntoView();
  }

  void _onViewportChanged() {
    _logDiagnostics();
    _scrollFocusedFieldIntoView();
  }

  /// Wait for the frame that applies the new padding, then scroll the
  /// focused field clear of the keyboard.
  void _scrollFocusedFieldIntoView() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final focusContext = FocusManager.instance.primaryFocus?.context;
      if (focusContext == null || !focusContext.mounted) return;
      Scrollable.ensureVisible(
        focusContext,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: const Duration(milliseconds: 150),
      );
    });
  }

  void _logDiagnostics() {
    if (_diagnosticsLogged >= 15) return;
    _diagnosticsLogged++;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Analytics.capture('keyboard_viewport_measured', properties: {
        'visible_bottom': visibleViewportBottom.value ?? -1,
        'app_height': MediaQuery.of(context).size.height,
        'ios_standalone': isIosStandalonePwa(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double?>(
      valueListenable: visibleViewportBottom,
      builder: (context, visibleBottom, _) {
        final mq = MediaQuery.of(context);
        var inset =
            KeyboardInsetOverride.measuredInset(mq.size.height, visibleBottom);
        if (inset == 0 && _textFieldFocused && isIosStandalonePwa()) {
          inset = KeyboardInsetOverride.estimatedInset(mq.size.height);
        }
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
