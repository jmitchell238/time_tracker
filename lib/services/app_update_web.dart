import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';

import 'analytics_service.dart';

/// True when a newer build of the app has been downloaded by the service
/// worker and is waiting to take over.
final ValueNotifier<bool> updateReady = ValueNotifier<bool>(false);

@JS('navigator.serviceWorker')
external _ServiceWorkerContainer? get _swContainer;

@JS('document')
external _EventTarget get _document;

@JS('window')
external _EventTarget get _window;

@JS('location')
external _Location get _location;

extension type _Location._(JSObject _) implements JSObject {
  external void reload();
}

extension type _EventTarget._(JSObject _) implements JSObject {
  external void addEventListener(String type, JSFunction callback);
}

extension type _ServiceWorkerContainer._(JSObject _) implements JSObject {
  external JSPromise<_ServiceWorkerRegistration?> getRegistration();
  external _ServiceWorker? get controller;
  external void addEventListener(String type, JSFunction callback);
}

extension type _ServiceWorkerRegistration._(JSObject _) implements JSObject {
  external _ServiceWorker? get waiting;
  external _ServiceWorker? get installing;
  external JSPromise<JSAny?> update();
  external void addEventListener(String type, JSFunction callback);
}

extension type _ServiceWorker._(JSObject _) implements JSObject {
  external String get state;
  external void postMessage(JSAny message);
  external void addEventListener(String type, JSFunction callback);
}

_ServiceWorkerRegistration? _registration;
bool _reloadScheduled = false;

void _reloadOnce() {
  if (_reloadScheduled) return;
  _reloadScheduled = true;
  _location.reload();
}

/// Watches the service worker for a newly downloaded build. iOS PWAs only
/// re-check the worker on cold launch and often get swiped away before the
/// download finishes, leaving users stuck on old builds — so we also check
/// whenever the app returns to the foreground and on a timer.
Future<void> initAppUpdateWatcher() async {
  final container = _swContainer;
  if (container == null) return;
  try {
    final reg = await container.getRegistration().toDart;
    if (reg == null) return;
    _registration = reg;

    // A controller means this page is already running some version, so a
    // waiting/installed worker is an update rather than a first install.
    void flagIfUpdateReady() {
      if (reg.waiting != null && container.controller != null && !updateReady.value) {
        updateReady.value = true;
        Analytics.capture('sw_update_ready');
      }
    }

    Analytics.capture('sw_watcher_init', properties: {
      'has_controller': container.controller != null,
      'has_waiting': reg.waiting != null,
      'has_installing': reg.installing != null,
    });

    void watchInstalling(_ServiceWorker? worker) {
      if (worker == null) return;
      worker.addEventListener('statechange', (() {
        if (worker.state == 'installed') flagIfUpdateReady();
      }).toJS);
    }

    flagIfUpdateReady();
    // An update discovered before this code ran may already be mid-install.
    watchInstalling(reg.installing);
    reg.addEventListener('updatefound', (() {
      watchInstalling(reg.installing);
    }).toJS);

    // Re-check with the server when the app comes back to the foreground.
    _document.addEventListener('visibilitychange', (() {
      reg.update();
    }).toJS);
    _window.addEventListener('focus', (() {
      reg.update();
    }).toJS);
    Timer.periodic(const Duration(minutes: 30), (_) {
      reg.update();
    });
    // Catch-all: statechange/updatefound events can be missed around page
    // load, but a waiting worker is directly observable.
    Timer.periodic(const Duration(seconds: 10), (_) {
      flagIfUpdateReady();
    });
  } catch (_) {}
}

/// Activate the waiting version and reload the app. Flutter's generated
/// service worker calls skipWaiting() when it receives this message; when
/// the new worker takes control we reload so the new assets are served.
void applyUpdate() {
  final container = _swContainer;
  final waiting = _registration?.waiting;
  if (container == null || waiting == null) {
    // Nothing waiting (already activated, or state was lost) — a plain
    // reload picks up whatever the newest active worker serves.
    _reloadOnce();
    return;
  }
  container.addEventListener('controllerchange', (() {
    _reloadOnce();
  }).toJS);
  waiting.postMessage('skipWaiting'.toJS);
  // Safety net: reload even if controllerchange never fires.
  Timer(const Duration(seconds: 3), _reloadOnce);
}
