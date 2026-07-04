import 'package:flutter/foundation.dart';

/// Bottom edge (in logical pixels, page coordinates) of the browser's visual
/// viewport — the area actually visible to the user. null means unavailable
/// (non-web platforms, or browsers without visualViewport support).
///
/// KeyboardInsetOverride compares this against the app's own height to work
/// out how much of the bottom of the app the on-screen keyboard covers.
final ValueNotifier<double?> visibleViewportBottom = ValueNotifier<double?>(null);

/// Whether the app is running as an iOS home-screen web app, where WebKit
/// reports no viewport change at all when the keyboard opens and the inset
/// must be estimated. Mutable so tests can fake it.
bool Function() isIosStandalonePwa = () => false;

void initKeyboardInset() {}
