import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/firebase_saves.dart';
import '../google_logic.dart';
import '../level_selection/levels.dart';
import '../utils/helper.dart';

class PlayerProgress extends ChangeNotifier {
  PlayerProgress() {
    g.loadUser();
    loadFromFirebaseOrFilesystem();
  }

  final Map<String, List<Map<String, int>>> _playerProgress = {"levels": []};

  int get maxLevelCompleted => _playerProgress["levels"]!.isEmpty
      ? Levels.tutorialLevelNum - 1
      : _playerProgress["levels"]!
          .map((item) => item["levelNum"] as int)
          .reduce(max);

  bool isComplete(int levelNum) {
    return _playerProgress["levels"]!
        .map((item) => item["levelNum"] as int)
        .contains(levelNum);
  }

  void saveLevelComplete(var currentGameState) {
    final Map<String, int> win = _cleanupWin(currentGameState);
    playerProgress._addWin(win);
    playerProgress._saveToFirebaseAndFilesystem();
    debug(["saveWin"]);
  }

  void reset() {
    _playerProgress.remove("levels");
    _playerProgress["levels"] = [];
    playerProgress._saveToFirebaseAndFilesystem();
  }

  void _addWin(Map<String, int> win) {
    if (!_playerProgress.keys.contains("levels")) {
      _playerProgress["levels"] = [];
    }
    final List<Map<String, int>> saveFileLevels = _playerProgress["levels"]!;
    Map? relevantSave = saveFileLevels
        .where((item) => item["levelNum"] == win["levelNum"])
        .firstOrNull;
    if (relevantSave == null) {
      saveFileLevels.add(win);
    } else if (win["levelCompleteTime"]! < relevantSave["levelCompleteTime"]!) {
      for (String key in win.keys) {
        relevantSave[key] = win[key];
      }
    }
    notifyListeners();
  }

  Future<void> loadFromFirebaseOrFilesystem() async {
    debug(["loadKeys"]);
    final prefs = await SharedPreferences.getInstance();
    String gameEncoded = "";

    if (!FBase.firebaseOn || !g.signedIn) {
      // load from local save
      gameEncoded = prefs.getString('game') ?? "";
    } else {
      // load from firebase
      gameEncoded = await fBase.firebasePullPlayerProgress();
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
      fBase.firebasePushPlayerProgress(gameEncoded);
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
