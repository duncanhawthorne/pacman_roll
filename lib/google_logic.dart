import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'flame_game/pacman_game.dart';
import 'player_progress/player_progress.dart';
import 'player_progress/user.dart';
import 'secrets.dart';
import 'utils/helper.dart';
import 'utils/src/sign_in_button/mobile.dart';

/// The type of the onClick callback for the (mobile) Sign In Button.
//typedef HandleSignInFn = Future<void> Function();

const bool _debugFakeLogin = false;
const String _gUserFakeLogin = "joebloggs@gmail.com";

final gOn = googleOnReal &&
    !(defaultTargetPlatform == TargetPlatform.windows && !kIsWeb);

class G {
  GoogleSignIn googleSignIn = GoogleSignIn(
    //gID defined in secrets.dart, not included in repo
    //in format XXXXXX.apps.googleusercontent.com
    clientId: gID,
    scopes: <String>[
      'email',
    ],
  );

  static const String gUserDefault = "JoeBloggs";
  static const String gUserIconDefault = "JoeBloggs";

  GoogleSignInAccount? _user;

  ValueNotifier<String> gUserNotifier = ValueNotifier("JoeBloggs");
  String _gUserIcon = "JoeBloggs";

  Future<void> loadUser() async {
    List<String> tmp = await user.loadFromFilesystem();
    gUser = tmp[0];
    gUserIcon = tmp[1];
  }

  void startGoogleAccountChangeListener() {
    if (gOn) {
      googleSignIn.onCurrentUserChanged
          .listen((GoogleSignInAccount? account) async {
        _user = account;
        if (_user != null) {
          debug(["login successful", _user]);
          _successfulLoginExtractDetails();
        } else {
          debug(["logout"]);
          _logoutExtractDetails();
        }
      });
    }
  }

  void signInSilently() async {
    if (gOn) {
      await googleSignIn.signInSilently();
      _successfulLoginExtractDetails();
    }
  }

  Future<void> signInDirectly() async {
    debug("webSignIn()");
    if (gOn) {
      try {
        if (_debugFakeLogin) {
          _debugLoginExtractDetails();
        } else {
          await googleSignIn.signIn();
          _successfulLoginExtractDetails();
        }
      } catch (e) {
        debug(["signInDirectly", e]);
      }
    }
  }

  Future<void> signOut() async {
    if (gOn) {
      if (_debugFakeLogin) {
      } else {
        try {
          await googleSignIn.disconnect();
          _logoutExtractDetails();
        } catch (e) {
          debug(["signOut", e]);
        }
      }
      //logoutExtractDetails(); //now handled by listener
    }
  }

  Future<void> signInSilentlyThenDirectly() async {
    debug("mobileSignIn()");
    if (gOn) {
      if (_debugFakeLogin) {
        _debugLoginExtractDetails();
      } else {
        await googleSignIn.signInSilently();
        _user = googleSignIn.currentUser;

        if (_user == null) {
          //if sign in silently didn't work
          await googleSignIn.signIn();
          _user = googleSignIn.currentUser;
        }
        _successfulLoginExtractDetails();
      }
    }
  }

  void _successfulLoginExtractDetails() async {
    if (_user != null) {
      debug("login extract details");
      gUser = _user!.email;
      if (_user!.photoUrl != null) {
        gUserIcon = _user!.photoUrl ?? gUserIconDefault;
      }
      await user.saveToFilesystem(gUser, gUserIcon);
      await playerProgress.loadFromFirebaseOrFilesystem();
    }
  }

  void _debugLoginExtractDetails() async {
    debug("debugLoginExtractDetails");
    assert(_debugFakeLogin);
    gUser = _gUserFakeLogin;
    await user.saveToFilesystem(gUser, gUserIcon);
    await playerProgress.loadFromFirebaseOrFilesystem();
  }

  void _logoutExtractDetails() async {
    debug("logout extract details");
    gUser = gUserDefault;
    await user.saveToFilesystem(gUser, gUserIcon);
    await playerProgress.loadFromFirebaseOrFilesystem();
  }

  Future<void> signOutAndExtractDetails() async {
    debug("sign out and extract details");
    if (gOn) {
      await signOut();
      _logoutExtractDetails();
    }
  }

  Widget platformAdaptiveSignInButton(BuildContext context, PacmanGame game) {
    // different buttons depending on web or mobile. See sign_in_button folder
    return buildSignInButton(
        onPressed:
            signInDirectly, //relevant on web only, else uses separate code
        context: context,
        game: game);
  }

  bool get signedIn => gUser != gUserDefault;

  String get gUser => gUserNotifier.value;

  String get gUserIcon => _gUserIcon;

  set gUser(g) => gUserNotifier.value = g;

  set gUserIcon(gui) => _gUserIcon = gui;
}

final G g = G();
