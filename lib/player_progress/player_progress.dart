import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/firebase_saves.dart';
import '../google/google.dart';
import '../level_selection/levels.dart';

class PlayerProgress extends ChangeNotifier {
  PlayerProgress._() {
    _userChangeListener();
  }

  factory PlayerProgress() {
    assert(_instance == null);
    _instance ??= PlayerProgress._();
    return _instance!;
  }

  ///ensures singleton [PlayerProgress]
  static PlayerProgress? _instance;

  static final Logger _log = Logger('PP');

  void _userChangeListener() {
    _loadFromFirebaseOrFilesystem(); //initial
    g.gUserNotifier.addListener(() {
      _loadFromFirebaseOrFilesystem();
    });
  }

  final List<Map<String, int>> _playerProgressLevels = <Map<String, int>>[];
  late final Map<String, dynamic> _playerProgress = <String, dynamic>{
    "levels": _playerProgressLevels,
  };

  Iterable<int> get _levelNumsCompleted =>
      _playerProgressLevels.map((Map<String, int> item) => item["levelNum"]!);

  int get maxLevelCompleted => _playerProgressLevels.isEmpty
      ? Levels.minLevel - 1
      : _levelNumsCompleted.reduce(max);

  bool isComplete(int levelNum) {
    return _levelNumsCompleted.contains(levelNum);
  }

  void saveLevelComplete(Map<String, dynamic> currentGameState) {
    _log.info("saveWin");
    final Map<String, int> win = _cleanupWin(currentGameState);
    _addWin(win);
    _saveToFirebaseAndFilesystem();
  }

  void reset() {
    _playerProgressLevels.clear();
    _saveToFirebaseAndFilesystem();
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
    _log.info("loadKeys");
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
    _log.info(<String>["saveKeys", gameEncoded]);
    // save locally
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('game', gameEncoded);

    // if possible save to firebase
    if (FBase.firebaseOn && g.signedIn) {
      _log.info("saveKeys gUser ${g.gUser}");
      await fBase.firebasePushPlayerProgress(g, gameEncoded);
    } else {
      _log.info("not signed in ${g.gUser}");
    }
  }

  String _getEncodeCurrent() {
    return json.encode(_playerProgress);
  }

  void _loadFromEncoded(String gameEncoded, bool sync) {
    if (gameEncoded == "") {
      _log.info("blank load");
    } else {
      try {
        final dynamic jsonGameTmp = json.decode(gameEncoded);
        final dynamic jsonLevels = jsonGameTmp["levels"];
        if (jsonLevels != null) {
          for (dynamic jsonLevel in jsonLevels) {
            final Map<String, int> win = _cleanupWin(jsonLevel);
            _addWin(win);
          }
        }
      } catch (e) {
        _log.severe("Malformed load $e");
      }
    }
  }
}

Map<String, int> _cleanupWin(Map<String, dynamic> winRaw) {
  final Map<String, int> result = <String, int>{
    "levelNum": -1,
    "mazeId": -1,
    "levelCompleteTime": -1,
    "dateTime": -1,
  };
  for (final String key in result.keys) {
    result[key] = winRaw[key] as int;
  }
  return result;
}
