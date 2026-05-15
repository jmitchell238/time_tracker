import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class Analytics {
  Analytics._();

  static Future<void> setup() async {
    try {
      final config = PostHogConfig('phc_w7X8UWgXx5FTArwLoLLfhaQ5ouxwoNaS3v2yGSuqKiLU')
        ..host = 'https://us.i.posthog.com'
        ..debug = kDebugMode
        ..captureApplicationLifecycleEvents = false;
      await Posthog().setup(config);
    } catch (_) {}
  }

  static void identify(String userId) {
    try {
      Posthog().identify(userId: userId).catchError((_) {});
    } catch (_) {}
  }

  static void reset() {
    try {
      Posthog().reset().catchError((_) {});
    } catch (_) {}
  }

  static void screen(String name) {
    try {
      Posthog().screen(screenName: name).catchError((_) {});
    } catch (_) {}
  }

  static void capture(String event, {Map<String, Object>? properties}) {
    try {
      Posthog().capture(eventName: event, properties: properties).catchError((_) {});
    } catch (_) {}
  }
}
