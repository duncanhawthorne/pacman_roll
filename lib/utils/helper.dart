import 'dart:core';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'title_fix_stub.dart' if (dart.library.js_interop) 'title_fix_web.dart';

/// This file has utilities used by other bits of code

double smallAngle(double angleDelta) {
  //avoid +2*pi-delta jump when go around the circle, instead give -delta
  angleDelta = angleDelta % (2 * pi);
  return angleDelta > 2 * pi / 2 ? angleDelta - 2 * pi : angleDelta;
}

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
