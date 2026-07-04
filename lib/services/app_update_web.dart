import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';

import 'analytics_service.dart';

/// True when a newer build of the app is available — detected either through
/// the service worker (a new worker waiting) or by polling the server for a
/// changed flutter_bootstrap.js (which embeds a per-build hash).
final ValueNotifier<bool> updateReady = ValueNotifier<bool>(false);

@JS('navigator.serviceWorker')
external _ServiceWorkerContainer? get _swContainer;

@JS('document')
external _EventTarget get _document;

@JS('window')
external _EventTarget get _window;

@JS('location')
external _Location get _location;

@JS('fetch')
external JSPromise<_FetchResponse> _fetch(JSString url);

extension type _Location._(JSObject _) implements JSObject {
  external void reload();
}

extension type _FetchResponse._(JSObject _) implements JSObject {
  external bool get ok;
  external JSPromise<JSString> text();
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
  external JSPromise<JSBoolean> unregister();
  external void addEventListener(String type, JSFunction callback);
}

extension type _ServiceWorker._(JSObject _) implements JSObject {
  external String get state;
  external void postMessage(JSAny message);
  external void addEventListener(String type, JSFunction callback);
}

_ServiceWorkerRegistration? _registration;
bool _reloadScheduled = false;
String? _bootstrapAtLaunch;
bool _pollSawNewVersion = false;

void _reloadOnce() {
  if (_reloadScheduled) return;
  _reloadScheduled = true;
  _location.reload();
}

/// One-line summary of the update machinery's live state, shown in Settings
/// so a screenshot can tell us whether the service worker works on a device.
String updateDebugInfo() {
  final reg = _registration;
  final container = _swContainer;
  final swPart = 'reg:${reg != null ? 'y' : 'n'} '
      'ctrl:${container?.controller != null ? 'y' : 'n'} '
      'wait:${reg?.waiting != null ? 'y' : 'n'}';
  final pollPart = _bootstrapAtLaunch == null
      ? 'off'
      : (_pollSawNewVersion ? 'new!' : 'ok');
  return 'sw $swPart · poll:$pollPart';
}

Future<String?> _fetchBootstrap() async {
  try {
    // Query param defeats every HTTP cache layer.
    final url = 'flutter_bootstrap.js?u=${DateTime.now().millisecondsSinceEpoch}';
    final resp = await _fetch(url.toJS).toDart;
    if (!resp.ok) return null;
    return (await resp.text().toDart).toDart;
  } catch (_) {
    return null;
  }
}

Future<void> _checkForNewVersionByPoll() async {
  final baseline = _bootstrapAtLaunch;
  if (baseline == null || _pollSawNewVersion) return;
  final latest = await _fetchBootstrap();
  if (latest != null && latest != baseline) {
    _pollSawNewVersion = true;
    if (!updateReady.value) {
      updateReady.value = true;
      Analytics.capture('update_detected_via_poll');
    }
  }
}

/// Watches for a newly deployed build through two independent channels:
/// the service worker lifecycle (when the browser supports/allows it) and a
/// direct server poll of flutter_bootstrap.js, whose embedded build hash
/// changes on every deploy. iOS PWAs have unreliable service worker update
/// behavior, so the poll is the safety net that always works.
Future<void> initAppUpdateWatcher() async {
  // Server-poll channel — independent of the service worker.
  _bootstrapAtLaunch = await _fetchBootstrap();
  _document.addEventListener('visibilitychange', (() {
    _checkForNewVersionByPoll();
  }).toJS);
  _window.addEventListener('focus', (() {
    _checkForNewVersionByPoll();
  }).toJS);
  Timer.periodic(const Duration(minutes: 5), (_) {
    _checkForNewVersionByPoll();
  });

  // Service worker channel.
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
      'poll_baseline': _bootstrapAtLaunch != null,
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

/// Activate the new version. If a service worker is waiting, tell it to take
/// over (Flutter's worker handles the 'skipWaiting' message) and reload when
/// it does; otherwise just reload — with no-cache headers on the core files,
/// a plain reload fetches the newest build.
void applyUpdate() {
  final container = _swContainer;
  final reg = _registration;
  final waiting = reg?.waiting;
  if (container == null || waiting == null) {
    if (reg != null && _pollSawNewVersion) {
      // The poll saw a new deploy but no worker is waiting — an old active
      // worker would serve its stale cache on reload, so drop it first.
      reg.unregister().toDart.then((_) => _reloadOnce(), onError: (_) => _reloadOnce());
      Timer(const Duration(seconds: 2), _reloadOnce);
    } else {
      _reloadOnce();
    }
    return;
  }
  container.addEventListener('controllerchange', (() {
    _reloadOnce();
  }).toJS);
  waiting.postMessage('skipWaiting'.toJS);
  // Safety net: reload even if controllerchange never fires.
  Timer(const Duration(seconds: 3), _reloadOnce);
}
