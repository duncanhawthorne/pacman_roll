import 'dart:core';

import 'src/stub.dart' if (dart.library.js_interop) 'src/web.dart';

void blockTouchDefault(bool enable) {
  // prevent double tap magnifier showing on ios web
  blockTouchDefaultReal(enable);
}
