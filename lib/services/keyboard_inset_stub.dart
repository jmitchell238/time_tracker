import 'package:flutter/foundation.dart';

/// Bottom edge (in logical pixels, page coordinates) of the browser's visual
/// viewport — the area actually visible to the user. null means unavailable
/// (non-web platforms, or browsers without visualViewport support).
///
/// KeyboardInsetOverride compares this against the app's own height to work
/// out how much of the bottom of the app the on-screen keyboard covers.
final ValueNotifier<double?> visibleViewportBottom = ValueNotifier<double?>(null);

/// Whether the app is running in a browser on an iOS device, where WebKit
/// often reports no viewport change at all when the keyboard opens and the
/// inset must be estimated. Mutable so tests can fake it.
bool Function() isIosWeb = () => false;

/// Raw detection values for diagnostics. Empty off-web.
String keyboardDebugInfo() => '';

void initKeyboardInset() {}
