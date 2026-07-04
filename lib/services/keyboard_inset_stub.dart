import 'package:flutter/foundation.dart';

/// Height in logical pixels of the strip at the bottom of the window covered
/// by the on-screen keyboard. Always 0 off-web; the web implementation
/// measures it from the browser's visualViewport.
final ValueNotifier<double> keyboardInset = ValueNotifier<double>(0);

void initKeyboardInset() {}
