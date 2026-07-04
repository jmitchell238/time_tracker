import 'dart:js_interop';

import 'package:flutter/foundation.dart';

/// Bottom edge (in logical pixels, page coordinates) of the browser's visual
/// viewport — the area actually visible to the user. null until the first
/// measurement.
final ValueNotifier<double?> visibleViewportBottom = ValueNotifier<double?>(null);

@JS('visualViewport')
external _VisualViewport? get _visualViewport;

@JS('navigator')
external _Navigator get _navigator;

extension type _Navigator._(JSObject _) implements JSObject {
  external String get userAgent;
  external double get maxTouchPoints;
  // iOS Safari only: true when launched from a home-screen icon.
  external JSBoolean? get standalone;
}

@JS('matchMedia')
external _MediaQueryList _matchMedia(String query);

extension type _MediaQueryList._(JSObject _) implements JSObject {
  external bool get matches;
}

bool _isIosDevice() {
  try {
    final ua = _navigator.userAgent;
    if (RegExp('iPhone|iPad|iPod').hasMatch(ua)) return true;
    // iPadOS masquerades as a Mac but Macs have no touch points.
    return ua.contains('Macintosh') && _navigator.maxTouchPoints > 1;
  } catch (_) {
    return false;
  }
}

/// Whether the app is running in a browser on an iOS device, where WebKit
/// often reports no viewport change at all when the keyboard opens and the
/// inset must be estimated. Detected by user agent rather than
/// navigator.standalone, which modern iOS builds don't reliably set.
/// Mutable so tests can fake it.
bool Function() isIosWeb = _isIosDevice;

/// Raw detection values for diagnostics.
String keyboardDebugInfo() {
  bool? standalone;
  bool? displayModeStandalone;
  try {
    standalone = _navigator.standalone?.toDart;
  } catch (_) {}
  try {
    displayModeStandalone = _matchMedia('(display-mode: standalone)').matches;
  } catch (_) {}
  return 'ios:${_isIosDevice()} st:$standalone dm:$displayModeStandalone '
      'vvB:${visibleViewportBottom.value}';
}

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
