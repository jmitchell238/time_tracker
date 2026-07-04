import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';

/// True when a newer build of the app has been downloaded by the service
/// worker and is waiting to take over.
final ValueNotifier<bool> updateReady = ValueNotifier<bool>(false);

@JS('navigator.serviceWorker')
external _ServiceWorkerContainer? get _swContainer;

@JS('document')
external _EventTarget get _document;

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
/// whenever the app returns to the foreground and every 30 minutes.
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
      if (reg.waiting != null && container.controller != null) {
        updateReady.value = true;
      }
    }

    flagIfUpdateReady();
    reg.addEventListener('updatefound', (() {
      final installing = reg.installing;
      if (installing == null) return;
      installing.addEventListener('statechange', (() {
        if (installing.state == 'installed' && container.controller != null) {
          updateReady.value = true;
        }
      }).toJS);
    }).toJS);

    _document.addEventListener('visibilitychange', (() {
      reg.update();
    }).toJS);
    Timer.periodic(const Duration(minutes: 30), (_) {
      reg.update();
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
