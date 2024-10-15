import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../google/src/sign_in_button/mobile.dart';
import '../utils/helper.dart';
import 'secrets.dart';

/// The type of the onClick callback for the (mobile) Sign In Button.
//typedef HandleSignInFn = Future<void> Function();

const bool _debugFakeLogin = false;
const String _gUserFakeLogin = "joebloggs@gmail.com";

final bool gOn = googleOnReal &&
    !(defaultTargetPlatform == TargetPlatform.windows && !kIsWeb);

class G {
  G() {
    _startGoogleAccountChangeListener();
    _loadUser();
  }

  bool get signedIn => gUser != _gUserDefault;

  String get gUser => gUserNotifier.value;

  set _gUser(String g) => <void>{
        debug(<dynamic>["gUserChanged", g]),
        gUserNotifier.value = g
      };

  double _iconWidth = 1;
  Color _color = Colors.white;

  Widget loginLogoutWidget(
      BuildContext context, double iconWidth, Color color) {
    _iconWidth = iconWidth;
    _color = color;
    return !gOn
        ? const SizedBox.shrink()
        : ValueListenableBuilder<String>(
            valueListenable: gUserNotifier,
            builder: (BuildContext context, String audioOn, Widget? child) {
              return !signedIn ? _loginButton(context) : _logoutButton(context);
            });
  }

  Widget _loginButton(BuildContext context) {
    const bool newLoginButtons = false;
    return newLoginButtons
        // ignore: dead_code
        ? _platformAdaptiveSignInButton(context)
        : lockStyleSignInButton(context);
  }

  Widget lockStyleSignInButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.lock, color: _color),
      onPressed: () {
        _signInSilentlyThenDirectly();
      },
    );
  }

  Widget _platformAdaptiveSignInButton(BuildContext context) {
    // different buttons depending on web or mobile. See sign_in_button folder
    return buildSignInButton(
        onPressed:
            _signInDirectly, //relevant on web only, else uses separate code
        context: context,
        g: this);
  }

  Widget _logoutButton(BuildContext context) {
    return IconButton(
      icon: _gUserIcon == G._gUserIconDefault
          ? Icon(Icons.face_outlined, color: _color)
          : CircleAvatar(
              radius: _iconWidth / 2,
              backgroundImage: NetworkImage(_gUserIcon)),
      onPressed: () {
        _signOutAndExtractDetails();
      },
    );
  }

  GoogleSignIn googleSignIn = GoogleSignIn(
    //gID defined in secrets.dart, not included in repo
    //in format XXXXXX.apps.googleusercontent.com
    clientId: gID,
    scopes: <String>[
      'email',
    ],
  );

  Future<List<String>> _loadUserFromFilesystem() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String gUser = prefs.getString('gUser') ?? G._gUserDefault;
    final String gUserIcon =
        prefs.getString('gUserIcon') ?? G._gUserIconDefault;
    debug(<String>["loadUser", gUser, gUserIcon]);
    return <String>[gUser, gUserIcon];
  }

  Future<void> _saveUserToFilesystem(String gUser, String gUserIcon) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('gUser', gUser);
    await prefs.setString('gUserIcon', gUserIcon);
    debug(<String>["saveUser", gUser, gUserIcon]);
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

  void _startGoogleAccountChangeListener() {
    if (gOn) {
      googleSignIn.onCurrentUserChanged
          .listen((GoogleSignInAccount? account) async {
        debug("gUser changed");
        _user = account;
        if (_user != null) {
          debug(<Object?>["login successful", _user]);
          unawaited(_successfulLoginExtractDetails());
        } else {
          debug(<String>["logout"]);
          unawaited(_logoutExtractDetails());
        }
      });
    }
  }

  // ignore: unused_element
  Future<void> _signInSilently() async {
    if (gOn) {
      await googleSignIn.signInSilently();
      unawaited(_successfulLoginExtractDetails());
    }
  }

  Future<void> _signInDirectly() async {
    debug("webSignIn()");
    if (gOn) {
      try {
        if (_debugFakeLogin) {
          unawaited(_debugLoginExtractDetails());
        } else {
          await googleSignIn.signIn();
          unawaited(_successfulLoginExtractDetails());
        }
      } catch (e) {
        debug(<Object>["signInDirectly", e]);
      }
    }
  }

  Future<void> _signOut() async {
    if (gOn) {
      if (_debugFakeLogin) {
      } else {
        try {
          await googleSignIn.disconnect();
          unawaited(_logoutExtractDetails());
        } catch (e) {
          debug(<Object>["signOut", e]);
        }
      }
      //logoutExtractDetails(); //now handled by listener
    }
  }

  Future<void> _signInSilentlyThenDirectly() async {
    debug("mobileSignIn()");
    if (gOn) {
      if (_debugFakeLogin) {
        unawaited(_debugLoginExtractDetails());
      } else {
        await googleSignIn.signInSilently();
        _user = googleSignIn.currentUser;

        if (_user == null) {
          //if sign in silently didn't work
          await googleSignIn.signIn();
          _user = googleSignIn.currentUser;
        }
        unawaited(_successfulLoginExtractDetails());
      }
    }
  }

  Future<void> _successfulLoginExtractDetails() async {
    if (_user != null) {
      debug("login extract details");
      _gUser = _user!.email;
      if (_user!.photoUrl != null) {
        _gUserIcon = _user!.photoUrl ?? _gUserIconDefault;
      }
      await _saveUserToFilesystem(gUser, _gUserIcon);
      debug(<String>["gUser", gUser]);
    }
  }

  Future<void> _debugLoginExtractDetails() async {
    debug("debugLoginExtractDetails");
    assert(_debugFakeLogin);
    _gUser = _gUserFakeLogin;
    await _saveUserToFilesystem(gUser, _gUserIcon);
    debug(<String>["gUser", gUser]);
  }

  Future<void> _logoutExtractDetails() async {
    debug("logout extract details");
    _gUser = _gUserDefault;
    assert(!signedIn);
    await _saveUserToFilesystem(gUser, _gUserIcon);
    debug(<String>["gUser", gUser]);
  }

  Future<void> _signOutAndExtractDetails() async {
    debug("sign out and extract details");
    if (gOn) {
      await _signOut();
      unawaited(_logoutExtractDetails());
    }
  }
}

final G g = G();
