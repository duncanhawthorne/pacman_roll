import 'dart:js_interop'; // Import the dart:js library

/// Represents the JavaScript function `greetUser`
@JS('setPreventTouchDefault')
external void setPreventTouchDefault(JSBoolean enable);

void setPreventTouchDefaultInJs(bool enable) {
  print(<Object>["setPreventTouchDefaultInJs1", enable]);
  setPreventTouchDefault(enable.toJS);
}
