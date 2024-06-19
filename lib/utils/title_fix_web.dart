import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:web/web.dart' as web;

import 'constants.dart';

/// This file runs only on the web and contains fixes for iOS safari / chrome

final isiOSMobile = kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

void fixTitleReal(Color color) {
  if (isiOSMobile) {
    //fixTitle1(color);
    //fixTitle2();
    fixTitle3();
  }
}

void fixTitle1(Color color) {
  //https://github.com/flutter/flutter/issues/98248
  if (true) {
    SystemChrome.setApplicationSwitcherDescription(ApplicationSwitcherDescription(
        label: appTitle,
        primaryColor: color
            .value //Theme.of(context).primaryColor.value, // This line is required
        ));
  }
}

void fixTitle2() {
  var url = web.window.location.href;
  web.window.history.replaceState(
    //or pushState
    web.window.history.state, // Note that we don't change the historyState
    appTitle,
    url,
  );
}

void fixTitle3() {
  var url = web.window.location.href;
  web.window.history.pushState(
    web.window.history.state, // Note that we don't change the historyState
    appTitle,
    url,
  );
}
