import 'dart:js_interop'; // Import the dart:js library

import 'package:logging/logging.dart';

/// Represents the JavaScript function `greetUser`
@JS('setPreventTouchDefault')
external void setPreventTouchDefault(JSBoolean enable);

final Logger _log = Logger('GT');

void setPreventTouchDefaultInJs(bool enable) {
  _log.fine(<Object>["setPreventTouchDefaultInJs1", enable]);
  setPreventTouchDefault(enable.toJS);
}
