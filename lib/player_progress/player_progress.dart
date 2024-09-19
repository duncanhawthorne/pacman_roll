import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../level_selection/levels.dart';
import 'persistence/local_storage_player_progress_persistence.dart';
import 'persistence/player_progress_persistence.dart';

/// Encapsulates the player's progress.
class PlayerProgress extends ChangeNotifier {
  PlayerProgress({PlayerProgressPersistence? store})
      : _store = store ?? LocalStoragePlayerProgressPersistence() {
    unawaited(_getLatestFromStore());
  }

  /// TODO: If needed, replace this with some other mechanism for saving
  ///       the player's progress. Currently, this uses the local storage
  ///       (i.e. NSUserDefaults on iOS, SharedPreferences on Android
  ///       or local storage on the web).
  final PlayerProgressPersistence _store;

  Map<int, int> _levelsFinished = {};

  /// The times for the levels that the player has finished so far.
  Map<int, int> get levels => _levelsFinished;

  int get maxLevelCompleted =>
      levels.isEmpty ? tutorialLevelNum - 1 : levels.keys.toList().reduce(max);

  /// Fetches the latest data from the backing persistence store.
  Future<void> _getLatestFromStore() async {
    final levelsFinished = await _store.getFinishedLevels();
    if (!mapEquals(_levelsFinished, levelsFinished)) {
      _levelsFinished = levelsFinished;
      notifyListeners();
    }
  }

  /// Resets the player's progress so it's like if they just started
  /// playing the game for the first time.
  void reset() {
    _store.reset();
    _levelsFinished.clear();
    notifyListeners();
  }

  /// Registers [level] as reached.
  ///
  /// If this is higher than [highestLevelReached], it will update that
  /// value and save it to the injected persistence store.
  void setLevelFinished(int level, int time) {
    if (_levelsFinished.containsKey(level)) {
      final int currentTime = _levelsFinished[level]!;
      if (time < currentTime) {
        _levelsFinished[level] = time;
        notifyListeners();
        unawaited(_store.saveLevelFinished(level, time));
      }
    } else {
      _levelsFinished[level] = time;
      notifyListeners();
      unawaited(_store.saveLevelFinished(level, time));
    }
  }
}
