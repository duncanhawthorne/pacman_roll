import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ios_web_touch_override/flutter_ios_web_touch_override.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'google_widget.dart';

class G {
  G._({required this.gOn, required this.clientId}) {
    _loadUser();
    _loggingInProcessListener();
  }

  factory G({required bool gOn, required String clientId}) {
    assert(_instance == null);
    _instance ??= G._(gOn: gOn, clientId: clientId);
    return _instance!;
  }

  ///ensures singleton [G]
  static G? _instance;

  Function()? googleWidgetLogoutFunction;
  Function()? googleLogoutConfirmationFunction;

  final bool gOn;
  final String clientId;

  late final GoogleSignInWidget gWidget = GoogleSignInWidget(
    clientId: clientId,
    serverClientId: null,
  );

  static final Logger _log = Logger('GG');

  ValueNotifier<bool> loggingInProcess = ValueNotifier<bool>(false);

  bool get signedIn => gUser != _gUserDefault;

  String get gUser => gUserNotifier.value;

  set _gUser(String g) => <void>{
    _log.info("gUserChanged $g"),
    gUserNotifier.value = g,
  };

  double _iconWidth = 1;
  Color _color = Colors.white;

  void _loggingInProcessListener() {
    blockTouchDefault(true);
    loggingInProcess.addListener(() {
      blockTouchDefault(!loggingInProcess.value);
    });
  }

  Widget loginLogoutWidget(
    BuildContext context,
    double iconWidth,
    Color color,
  ) {
    _iconWidth = iconWidth;
    _color = color;
    return !gOn
        ? const SizedBox.shrink()
        : ValueListenableBuilder<String>(
            valueListenable: gUserNotifier,
            builder: (BuildContext context, String _, Widget? child) {
              return !signedIn ? _loginButton() : _logoutButton();
            },
          );
  }

  Widget _loginButton() {
    return IconButton(
      icon: Icon(Icons.lock, color: _color),
      onPressed: () {
        loggingInProcess.value = !loggingInProcess.value;
      },
    );
  }

  Widget _logoutButton() {
    return IconButton(
      icon: _gUserIcon == _gUserIconDefault
          ? Icon(Icons.face_outlined, color: _color)
          : CircleAvatar(
              radius: _iconWidth / 2,
              backgroundImage: NetworkImage(_gUserIcon),
            ),
      onPressed: () {
        _logoutNowOrAfterConfirmation();
      },
    );
  }

  void _logoutNowOrAfterConfirmation() {
    if (googleLogoutConfirmationFunction != null) {
      googleLogoutConfirmationFunction!();
    } else {
      logoutNow();
    }
  }

  void logoutNow() {
    _log.fine("logout");
    assert(googleWidgetLogoutFunction != null);
    if (googleWidgetLogoutFunction != null) {
      _log.fine("logout now");
      googleWidgetLogoutFunction!();
    } else {
      extractDetailsFromLogout();
    }
  }

  Future<List<String>> _loadUserFromFilesystem() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String gUser = prefs.getString('gUser') ?? _gUserDefault;
    final String gUserIcon = prefs.getString('gUserIcon') ?? _gUserIconDefault;
    _log.fine("loadUser $gUser");
    return <String>[gUser, gUserIcon];
  }

  Future<void> _saveUserToFilesystem(String gUser, String gUserIcon) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('gUser', gUser);
    await prefs.setString('gUserIcon', gUserIcon);
    _log.fine("saveUser $gUser");
  }

  static const String _gUserDefault = "JoeBloggs";
  static const String _gUserIconDefault = "JoeBloggs";

  GoogleSignInAccount? _user;

  ValueNotifier<String> gUserNotifier = ValueNotifier<String>("JoeBloggs");
  String _gUserIcon = "JoeBloggs";

  Future<void> _loadUser() async {
    final List<String> tmp = await _loadUserFromFilesystem();
    _gUser = tmp[0];
    _gUserIcon = tmp[1];
  }

  Future<void> extractDetailsFromLogin(GoogleSignInAccount targetUser) async {
    _user = targetUser;
    if (_user != null) {
      _log.fine("login extract details");
      loggingInProcess.value = false;
      _gUser = _user!.email;
      if (_user!.photoUrl != null) {
        _gUserIcon = _user!.photoUrl ?? _gUserIconDefault;
      }
      await _saveUserToFilesystem(gUser, _gUserIcon);
      _log.fine("gUser = $gUser");
    }
  }

  Future<void> extractDetailsFromLogout() async {
    _log.fine("logout extract details");
    loggingInProcess.value = false;
    _gUser = _gUserDefault;
    assert(!signedIn);
    await _saveUserToFilesystem(gUser, _gUserIcon);
    _log.fine("gUser =$gUser");
  }
}
