import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'player_progress_persistence.dart';

/// An implementation of [PlayerProgressPersistence] that uses
/// `package:shared_preferences`.
class LocalStoragePlayerProgressPersistence extends PlayerProgressPersistence {
  final Future<SharedPreferences> instanceFuture =
      SharedPreferences.getInstance();

  Map<int, int> decode(String gameEncoded) {
    Map<int, int> gameTmp = {};
    if (gameEncoded == "") {
      gameTmp = {};
    } else {
      gameTmp = json.decode(gameEncoded);
    }
    return gameTmp;
  }

  String encode(Map<int, int> gameEncoded) {
    return json.encode(gameEncoded);
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
