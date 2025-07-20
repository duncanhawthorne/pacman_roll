import 'dart:js_interop'; // Import the dart:js library
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart'; // Import the dart:js library
import 'package:logging/logging.dart';

final Logger _log = Logger('TO');

// Get references to the global window and document objects
@JS('window')
external JSWindow get window;

@JS('document')
external JSDocument get document;

// Define the JavaScript Window object interface
@JS()
extension type JSWindow._(JSObject _) implements JSObject {}

// Define the JavaScript Document object interface
@JS()
extension type JSDocument._(JSObject _) implements JSObject {
  external void addEventListener(
    String type,
    JSFunction listener,
    JSObject options,
  );

  external void removeEventListener(
    String type,
    JSFunction listener,
    JSObject options,
  );
}

// Define the JavaScript TouchEvent object interface
@JS()
extension type JSTouchEvent._(JSObject _) implements JSObject {
  external void preventDefault();
}

// The touchstart listener
final JSExportedDartFunction touchstartListener =
    ((JSTouchEvent e) {
      e.preventDefault();
    }).toJS;

// Create a JSObject for the addEventListener options
final JSObject options =
    JSObject()
      ..setProperty('passive'.toJS, false.toJS); // Convert key and value to JS

final bool _isiOSWeb = defaultTargetPlatform == TargetPlatform.iOS && kIsWeb;

void blockTouchDefaultReal(bool enable) {
  _log.fine(<Object>["blockTouchDefaultReal", enable, _isiOSWeb]);
  if (!_isiOSWeb) {
    return;
  }
  if (enable) {
    document.addEventListener('touchstart', touchstartListener, options);
  } else {
    document.removeEventListener('touchstart', touchstartListener, options);
  }
}
