import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'workarounds_stub.dart'
    if (dart.library.js_interop) 'workarounds_web.dart';

void setStatusBarColor(color) {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: color, // Status bar color
  ));
}

void fixTitlePerm() {
  // to workaround a bug in flutter on ios web
  titleFixPermReal();
}

void fixTitlePersistent() {
  for (int i = 0; i < 2; i++) {
    Future.delayed(Duration(seconds: i), () {
      fixTitle();
    });
  }
}

void fixTitle([Color color = Colors.transparent]) {
  return; //disabled
  // to workaround a bug in flutter on ios web
  // ignore: dead_code
  fixTitleReal(color); //either from web or stub depending on platform
}

double gestureInset() {
  // to workaround a bug in flutter on ios web
  return gestureInsetReal(); //either from web or stub depending on platform
}
