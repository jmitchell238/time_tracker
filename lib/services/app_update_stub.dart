import 'package:flutter/foundation.dart';

/// True when a newer build of the app has been downloaded by the service
/// worker and is waiting to take over. Always false off-web.
final ValueNotifier<bool> updateReady = ValueNotifier<bool>(false);

void initAppUpdateWatcher() {}

/// Activate the waiting version and reload the app.
void applyUpdate() {}

/// One-line summary of the update machinery's live state. Empty off-web.
String updateDebugInfo() => '';
