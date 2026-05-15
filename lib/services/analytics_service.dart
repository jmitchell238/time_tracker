import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class Analytics {
  Analytics._();

  static String _screen = 'unknown';
  static String? _userEmail;

  static Future<void> setup() async {
    try {
      final config = PostHogConfig('phc_w7X8UWgXx5FTArwLoLLfhaQ5ouxwoNaS3v2yGSuqKiLU')
        ..host = 'https://us.i.posthog.com'
        ..debug = kDebugMode
        ..captureApplicationLifecycleEvents = false;
      await Posthog().setup(config);
    } catch (_) {}
  }

  static void identify(String userId, {String? email}) {
    _userEmail = email ?? userId;
    try {
      Posthog().identify(
        userId: email ?? userId,
        userProperties: {
          if (email != null) 'email': email,
          'firebase_uid': userId,
        },
      ).catchError((_) {});
    } catch (_) {}
  }

  static void reset() {
    _userEmail = null;
    _screen = 'unknown';
    try {
      Posthog().reset().catchError((_) {});
    } catch (_) {}
  }

  static void screen(String name) {
    _screen = name;
    try {
      Posthog().screen(screenName: name).catchError((_) {});
    } catch (_) {}
  }

  static void capture(String event, {Map<String, Object>? properties}) {
    try {
      Posthog().capture(eventName: event, properties: properties).catchError((_) {});
    } catch (_) {}
  }

  /// Fire an event auto-decorated with the current screen and signed-in user.
  static void action(String event, {Map<String, Object>? properties}) {
    capture(event, properties: {
      'screen': _screen,
      if (_userEmail != null) 'user': _userEmail!,
      ...?properties,
    });
  }

  /// Wraps a callback so tapping fires [event] then executes the original callback.
  /// Returns null when [callback] is null (preserves disabled-button semantics).
  static VoidCallback? trackTap(String event, VoidCallback? callback,
      {Map<String, Object>? properties}) {
    if (callback == null) return null;
    return () {
      action(event, properties: properties);
      callback();
    };
  }
}
