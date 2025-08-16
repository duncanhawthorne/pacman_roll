// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';

import 'google.dart';
import 'src/web_wrapper.dart' as web;

class GoogleSignInWidget extends StatefulWidget {
  const GoogleSignInWidget({super.key, this.clientId, this.serverClientId});

  final String? clientId;
  final String? serverClientId;

  @override
  State createState() => _GoogleSignInWidgetState();
}

class _GoogleSignInWidgetState extends State<GoogleSignInWidget> {
  GoogleSignInAccount? _currentUser;

  static final Logger _log = Logger('GG');

  @override
  void initState() {
    super.initState();

    // #docregion Setup
    final GoogleSignIn signIn = GoogleSignIn.instance;
    unawaited(
      signIn
          .initialize(
            clientId: widget.clientId,
            serverClientId: widget.serverClientId,
          )
          .then((_) {
            signIn.authenticationEvents
                .listen(_handleAuthenticationEvent)
                .onError(_handleAuthenticationError);

            /// This example always uses the stream-based approach to determining
            /// which UI state to show, rather than using the future returned here,
            /// if any, to conditionally skip directly to the signed-in state.
            signIn.attemptLightweightAuthentication();
            g.googleWidgetLogoutFunction = _handleSignOut;
          }),
    );
    // #enddocregion Setup
  }

  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    // #docregion CheckAuthorization
    final GoogleSignInAccount? user = // ...
        // #enddocregion CheckAuthorization
        switch (event) {
          GoogleSignInAuthenticationEventSignIn() => event.user,
          GoogleSignInAuthenticationEventSignOut() => null,
        };

    if (!mounted) {
      _log.fine("not mounted 1");
      _currentUser = user;
    } else {
      setState(() {
        _currentUser = user;
      });
    }

    if (user != null) {
      await g.extractDetailsFromLogin(user);
    } else {
      await g.extractDetailsFromLogout();
    }
  }

  Future<void> _handleAuthenticationError(Object e) async {
    if (!mounted) {
      _log.fine("not mounted 2");
      _currentUser = null;
    } else {
      setState(() {
        _currentUser = null;
      });
    }
  }

  Future<void> _handleSignOut() async {
    _log.fine("widget sign out");
    // Disconnect instead of just signing out, to reset the example state as
    // much as possible.
    if (_currentUser == null) {
      // as already signed out, need to run run this manually
      // as there wont be an authentication event
      await g.extractDetailsFromLogout();
      await GoogleSignIn.instance.disconnect();
    } else {
      await GoogleSignIn.instance.disconnect();
    }
  }

  Widget _buildBody() {
    final GoogleSignInAccount? user = _currentUser;
    return user != null
        ? ElevatedButton(
            onPressed: _handleSignOut,
            child: const Text('SIGN OUT'),
          )
        : web.renderButton();
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }
}
