import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'player_progress_persistence.dart';

/// An implementation of [PlayerProgressPersistence] that uses
/// `package:shared_preferences`.
class LocalStoragePlayerProgressPersistence extends PlayerProgressPersistence {
  final Future<SharedPreferences> instanceFuture =
      SharedPreferences.getInstance();

  Map<int, int> decode(String gameEncoded) {
    Map<String, int> gameTmp = {};
    if (gameEncoded == "") {
      gameTmp = {};
    } else {
      Map<String, dynamic> jsonDecoded = json.decode(gameEncoded);
      for (String item in jsonDecoded.keys) {
        gameTmp[item] = jsonDecoded[item];
      }
    }
    return gameTmp.map<int, int>(
      (k, v) => MapEntry(int.parse(k), v), // parse String back to int
    );
  }

  String encode(Map<int, int> gameDecoded) {
    return json.encode(gameDecoded.map<String, int>(
      (k, v) => MapEntry(k.toString(), v), // convert int to String
    ));
  }

  @override
  Future<Map<int, int>> getFinishedLevels() async {
    final prefs = await instanceFuture;
    final gameEncoded = prefs.getString('levelsFinishedMap') ?? "";
    return decode(gameEncoded);
  }

  @override
  Future<void> saveLevelFinished(int level, int time) async {
    final prefs = await instanceFuture;
    final gameEncoded = prefs.getString('levelsFinishedMap') ?? "";
    Map<int, int> decoded = decode(gameEncoded);
    if (decoded.containsKey(level)) {
      final int currentTime = decoded[level]!;
      if (time < currentTime) {
        decoded[level] = time;
      }
    } else {
      decoded[level] = time;
    }
    await prefs.setString('levelsFinishedMap', encode(decoded));
  }

  @override
  Future<void> reset() async {
    final prefs = await instanceFuture;
    await prefs.remove('levelsFinishedMap');
  }
}
