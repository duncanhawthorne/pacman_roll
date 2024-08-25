import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'title_fix_stub.dart' if (dart.library.js_interop) 'title_fix_web.dart';

/// This file has utilities used by other bits of code

void debug(x) {
  debugPrint("D ${DateTime.now()} $x");
}

void setStatusBarColor(color) {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: color, // Status bar color
  ));
}

void fixTitle(Color color) {
  // to workaround a bug in flutter on ios web
  fixTitleReal(color); //either from web or stub depending on platform
}

double gestureInset() {
  // to workaround a bug in flutter on ios web
  return gestureInsetReal(); //either from web or stub depending on platform
}
