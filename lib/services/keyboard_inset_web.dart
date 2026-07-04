import 'dart:js_interop';

import 'package:flutter/foundation.dart';

/// Bottom edge (in logical pixels, page coordinates) of the browser's visual
/// viewport — the area actually visible to the user. null until the first
/// measurement.
final ValueNotifier<double?> visibleViewportBottom = ValueNotifier<double?>(null);

@JS('visualViewport')
external _VisualViewport? get _visualViewport;

extension type _VisualViewport._(JSObject _) implements JSObject {
  external double get height;
  external double get offsetTop;
  external void addEventListener(String type, JSFunction callback);
}

/// iOS overlays the on-screen keyboard instead of resizing the page, and the
/// Flutter engine reports viewInsets.bottom == 0, so fields end up hidden
/// behind the keyboard. The visualViewport is the only place the browser
/// exposes the truly visible area. We publish its bottom edge rather than a
/// keyboard height because window.innerHeight is unreliable as a baseline
/// (standalone PWAs shrink it with the keyboard; Safari tabs don't) — the
/// consumer compares against Flutter's own rendered height instead.
void initKeyboardInset() {
  final vv = _visualViewport;
  if (vv == null) return;

  void update() {
    visibleViewportBottom.value = vv.offsetTop + vv.height;
  }

  final callback = (() => update()).toJS;
  vv.addEventListener('resize', callback);
  vv.addEventListener('scroll', callback);
  update();
}
