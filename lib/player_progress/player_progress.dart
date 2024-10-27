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

  final List<Map<String, int>> _playerProgressLevels = <Map<String, int>>[];
  late final Map<String, dynamic> _playerProgress = <String, dynamic>{
    "levels": _playerProgressLevels
  };

  Iterable<int> get _levelNumsCompleted =>
      _playerProgressLevels.map((Map<String, int> item) => item["levelNum"]!);

  int get maxLevelCompleted => _playerProgressLevels.isEmpty
      ? Levels.min - 1
      : _levelNumsCompleted.reduce(max);

  bool isComplete(int levelNum) {
    return _levelNumsCompleted.contains(levelNum);
  }

  void saveLevelComplete(Map<String, dynamic> currentGameState) {
    debug(<String>["saveWin"]);
    final Map<String, int> win = _cleanupWin(currentGameState);
    playerProgress
      .._addWin(win)
      .._saveToFirebaseAndFilesystem();
  }

  void reset() {
    _playerProgressLevels.clear();
    playerProgress._saveToFirebaseAndFilesystem();
  }

  void _addWin(Map<String, int> win) {
    final Map<String, int>? relevantSave = _playerProgressLevels
        .where((Map<String, int> item) => item["levelNum"] == win["levelNum"])
        .firstOrNull;
    if (relevantSave == null) {
      _playerProgressLevels.add(win);
    } else if (win["levelCompleteTime"]! < relevantSave["levelCompleteTime"]!) {
      for (final String key in win.keys) {
        relevantSave[key] = win[key]!;
      }
    }
    notifyListeners();
  }

  Future<void> _loadFromFirebaseOrFilesystem() async {
    debug(<String>["loadKeys"]);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
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
    final String gameEncoded = _getEncodeCurrent();
    debug(<String>["saveKeys", gameEncoded]);
    // save locally
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('game', gameEncoded);

    // if possible save to firebase
    if (FBase.firebaseOn && g.signedIn) {
      debug(<String>["saveKeys gUser", g.gUser]);
      unawaited(fBase.firebasePushPlayerProgress(g, gameEncoded));
    } else {
      debug(<String>["not signed in", g.gUser]);
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
        final dynamic jsonGameTmp = json.decode(gameEncoded);
        final dynamic jsonLevels = jsonGameTmp["levels"];
        if (jsonLevels != null) {
          for (dynamic jsonLevel in jsonLevels) {
            final Map<String, int> win = _cleanupWin(jsonLevel);
            playerProgress._addWin(win);
          }
        }
      } catch (e) {
        debug(<Object>["malformed load", e]);
      }
    }
  }
}

PlayerProgress playerProgress = PlayerProgress();

Map<String, int> _cleanupWin(Map<String, dynamic> winRaw) {
  final Map<String, int> result = <String, int>{
    "levelNum": -1,
    "mazeId": -1,
    "levelCompleteTime": -1,
    "dateTime": -1
  };
  for (final String key in result.keys) {
    result[key] = winRaw[key] as int;
  }
  return result;
}
