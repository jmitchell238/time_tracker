import 'dart:js_interop';

import 'package:flutter/foundation.dart';

/// Height in logical pixels of the strip at the bottom of the window covered
/// by the on-screen keyboard, measured from the browser's visualViewport.
final ValueNotifier<double> keyboardInset = ValueNotifier<double>(0);

@JS('innerHeight')
external double get _innerHeight;

@JS('visualViewport')
external _VisualViewport? get _visualViewport;

extension type _VisualViewport._(JSObject _) implements JSObject {
  external double get height;
  external double get offsetTop;
  external void addEventListener(String type, JSFunction callback);
}

/// iOS Safari/PWA overlays the keyboard instead of resizing the page and the
/// Flutter engine reports viewInsets.bottom == 0, so fields end up hidden
/// behind the keyboard. The visualViewport is the only place the browser
/// exposes the true visible area.
void initKeyboardInset() {
  final vv = _visualViewport;
  if (vv == null) return;

  void update() {
    final covered = _innerHeight - vv.height - vv.offsetTop;
    keyboardInset.value = covered > 0 ? covered : 0;
  }

  final callback = (() => update()).toJS;
  vv.addEventListener('resize', callback);
  vv.addEventListener('scroll', callback);
}
