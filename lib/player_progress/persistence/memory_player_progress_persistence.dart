import 'dart:core';

import 'player_progress_persistence.dart';

/// An in-memory implementation of [PlayerProgressPersistence].
/// Useful for testing.
class MemoryOnlyPlayerProgressPersistence implements PlayerProgressPersistence {
  final Map<int, int> levels = {};

  @override
  Future<Map<int, int>> getFinishedLevels() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return levels;
  }

  @override
  Future<void> saveLevelFinished(int level, int time) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (levels.containsKey(level) && levels[level]! > time) {
      levels[level] = time;
    }
  }

  @override
  Future<void> reset() async {
    levels.clear();
  }
}
