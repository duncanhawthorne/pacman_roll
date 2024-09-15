import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
// ignore: depend_on_referenced_packages
import 'package:web/web.dart' as web;

import '../constants.dart';

/// This file runs only on the web and contains fixes for iOS safari / chrome

final isiOSMobile = kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

void titleFixPermReal() {
  //https://github.com/flutter/flutter/issues/98248#issuecomment-2351689196
  if (isiOSMobile) {
    setUrlStrategy(CustomPathStrategy(appTitle: appTitle));
  }
}

class CustomPathStrategy extends PathUrlStrategy {
  final String appTitle;

  CustomPathStrategy({required this.appTitle});

  @override
  void pushState(Object? state, String title, String url) {
    final pageTitle = title == "flutter" ? appTitle : title;
    super.pushState(state, pageTitle, url);
  }

  @override
  void replaceState(Object? state, String title, String url) {
    final pageTitle = title == "flutter" ? appTitle : title;
    super.pushState(state, pageTitle, url);
  }
}

void fixTitleReal(Color color) {
  if (isiOSMobile) {
    //fixTitle1(color);
    //fixTitle2();
    fixTitle3();
  }
}

/*
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
  String url = web.window.location.href;
  web.window.history.replaceState(
    //or pushState
    web.window.history.state, // Note that we don't change the historyState
    appTitle,
    url,
  );
}
 */

void fixTitle3() {
  String url = web.window.location.href;
  web.window.history.pushState(
    web.window.history.state, // Note that we don't change the historyState
    appTitle,
    url,
  );
}

final isPwa =
    kIsWeb && web.window.matchMedia('(display-mode: standalone)').matches;
// Check if it's web iOS
final isWebiOS = kIsWeb &&
    web.window.navigator.userAgent.contains(RegExp(r'iPad|iPod|iPhone'));

const double _iOSWebPWAInset = 25;

double gestureInsetReal() {
  // Check if it's an installed PWA
  return isPwa && isWebiOS ? _iOSWebPWAInset : 0;
}
