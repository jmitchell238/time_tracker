import 'package:flutter/foundation.dart';

/// Bottom edge (in logical pixels, page coordinates) of the browser's visual
/// viewport — the area actually visible to the user. null means unavailable
/// (non-web platforms, or browsers without visualViewport support).
///
/// KeyboardInsetOverride compares this against the app's own height to work
/// out how much of the bottom of the app the on-screen keyboard covers.
final ValueNotifier<double?> visibleViewportBottom = ValueNotifier<double?>(null);

void initKeyboardInset() {}
