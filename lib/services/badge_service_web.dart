import 'dart:js_interop';

@JS('navigator.setAppBadge')
external JSPromise _setAppBadge([JSNumber? count]);

@JS('navigator.clearAppBadge')
external JSPromise _clearAppBadge();

void setBadgeCount(int count) {
  try {
    if (count > 0) {
      _setAppBadge(count.toJS);
    } else {
      _clearAppBadge();
    }
  } catch (_) {}
}
