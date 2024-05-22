import 'constants.dart';
// ignore: depend_on_referenced_packages
import 'package:web/web.dart' as web;
import 'package:flutter/services.dart';

void fixTitleReal() {
  if (isiOSMobile) {
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(seconds: i), () {
        fixTitle1();
        fixTitle2();
        fixTitle3();
      });
    }
  }
}

void fixTitle1() {
  //https://github.com/flutter/flutter/issues/98248
  if (true) {
    SystemChrome.setApplicationSwitcherDescription(ApplicationSwitcherDescription(
        label: appTitle,
        primaryColor: const Color(0xFF000000)
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
