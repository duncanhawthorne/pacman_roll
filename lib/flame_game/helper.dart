import 'components/maze.dart';
import 'constants.dart';
import 'package:flutter/material.dart';
import 'dart:core';
//import 'package:sensors_plus/sensors_plus.dart';
import '../style/palette.dart';
import 'package:flutter/services.dart';
import 'title_fix_stub.dart' if (dart.library.js_interop) 'title_fix_web.dart';

/// This file has utilities used by other bits of code

final globalPalette = Palette(); //FIXME

void p(x) {
  debugPrint("///// A ${DateTime.now()} $x");
}

String getRandomString(random, int length) =>
    String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

void setStatusBarColor(color) {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: color, // Status bar color
  ));
}

void fixTitle(Color color) {
  fixTitleReal(color); //either from web or stub depending on platform
}
