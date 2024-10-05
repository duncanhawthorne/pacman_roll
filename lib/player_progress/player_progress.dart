import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/firebase_saves.dart';
import '../google/google.dart';
import '../level_selection/levels.dart';
import '../utils/helper.dart';

class PlayerProgress extends ChangeNotifier {
  PlayerProgress() {
    _userChangeListener();
  }

  void _userChangeListener() {
    _loadFromFirebaseOrFilesystem(); //initial
    g.gUserNotifier.addListener(() {
      _loadFromFirebaseOrFilesystem();
    });
  }

  final List<Map<String, int>> _playerProgressLevels = [];
  late final Map<String, dynamic> _playerProgress = {
    "levels": _playerProgressLevels
  };

  Iterable<int> get _levelNumsCompleted =>
      _playerProgressLevels.map((item) => item["levelNum"] as int);

  int get maxLevelCompleted => _playerProgressLevels.isEmpty
      ? Levels.tutorialLevelNum - 1
      : _levelNumsCompleted.reduce(max);

  bool isComplete(int levelNum) {
    return _levelNumsCompleted.contains(levelNum);
  }

  void saveLevelComplete(var currentGameState) {
    debug(["saveWin"]);
    final Map<String, int> win = _cleanupWin(currentGameState);
    playerProgress._addWin(win);
    playerProgress._saveToFirebaseAndFilesystem();
  }

  void reset() {
    _playerProgressLevels.clear();
    playerProgress._saveToFirebaseAndFilesystem();
  }

  void _addWin(Map<String, int> win) {
    Map? relevantSave = _playerProgressLevels
        .where((item) => item["levelNum"] == win["levelNum"])
        .firstOrNull;
    if (relevantSave == null) {
      _playerProgressLevels.add(win);
    } else if (win["levelCompleteTime"]! < relevantSave["levelCompleteTime"]!) {
      for (String key in win.keys) {
        relevantSave[key] = win[key];
      }
    }
    notifyListeners();
  }

  Future<void> _loadFromFirebaseOrFilesystem() async {
    debug(["loadKeys"]);
    final prefs = await SharedPreferences.getInstance();
    String gameEncoded = "";

    if (!FBase.firebaseOn || !g.signedIn) {
      // load from local save
      gameEncoded = prefs.getString('game') ?? "";
    } else {
      // load from firebase
      gameEncoded = await fBase.firebasePullPlayerProgress(g);
    }
    _loadFromEncoded(gameEncoded, true);
  }

  Future<void> _saveToFirebaseAndFilesystem() async {
    String gameEncoded = _getEncodeCurrent();
    debug(["saveKeys", gameEncoded]);
    // save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('game', gameEncoded);

    // if possible save to firebase
    if (FBase.firebaseOn && g.signedIn) {
      debug(["saveKeys gUser", g.gUser]);
      fBase.firebasePushPlayerProgress(g, gameEncoded);
    } else {
      debug(["not signed in", g.gUser]);
    }
  }

  String _getEncodeCurrent() {
    return json.encode(_playerProgress);
  }

  void _loadFromEncoded(String gameEncoded, bool sync) {
    if (gameEncoded == "") {
      debug("blank gameEncoded");
    } else {
      try {
        final jsonGameTmp = json.decode(gameEncoded);
        final jsonLevels = jsonGameTmp["levels"];
        if (jsonLevels != null) {
          for (var jsonLevel in jsonLevels) {
            final Map<String, int> win = _cleanupWin(jsonLevel);
            playerProgress._addWin(win);
          }
        }
      } catch (e) {
        debug(["malformed load", e]);
      }
    }
  }
}

PlayerProgress playerProgress = PlayerProgress();

Map<String, int> _cleanupWin(var winRaw) {
  Map<String, int> result = {
    "levelNum": -1,
    "mazeId": -1,
    "levelCompleteTime": -1,
    "dateTime": -1
  };
  for (String key in result.keys) {
    result[key] = winRaw[key] as int;
  }
  return result;
}
