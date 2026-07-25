import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../level_selection/levels.dart';
import '../../utils/helper.dart';
import '../../utils/stored_moves.dart';
import '../components/base_component.dart';
import '../custom_game.dart';
import '../custom_world.dart';

/// Manages the recording and playback of maze rotation moves.
///
/// This is used for a special "playback mode" level.
class Playback extends BaseComponent with HasWorldReference<CustomWorld> {
  late final CustomGame game;

  int _counter = 0;
  bool _playbackModeEverDismissed = false;

  /// If true, the game will record moves during play.
  static const bool recordMode = kDebugMode && false;
  final List<List<double>> _recordedMovesLive = <List<double>>[];

  /// Enables the playback mode functionality.
  void enable() {
    _playbackModeEverDismissed = false;
  }

  /// Disables the playback mode functionality.
  void disable() {
    _playbackModeEverDismissed = true;
  }

  /// Checks if playback mode should be active for the current level and state.
  bool isPlaybackAppropriate() {
    return !_playbackModeEverDismissed & !recordMode &&
        game.level.number == Levels.playbackModeLevel;
  }

  /// Records the current maze angle at the current game time.
  void recordAngle(double angle) {
    if (!(recordMode && !(game.playState == PlayState.playbackMode))) return;
    _recordedMovesLive.add(<double>[
      (game.session.stopwatchMilliSeconds).toDouble(),
      angle,
    ]);
    if (_recordedMovesLive.length % 100 == 0) {
      logGlobal(_recordedMovesLive);
    }
  }

  /// Replays recorded moves by setting the maze angle based on the stopwatch time.
  void _playbackAngles() {
    if (!(game.playState == PlayState.playbackMode && game.isLive)) return;
    final int stopwatch = game.session.stopwatchMilliSeconds;
    if (stopwatch > 20000) {
      game.reset(); //if stuck, reset
      return;
    }
    while (_counter + 1 < storedMoves.length &&
        storedMoves[_counter + 1][0] < stopwatch) {
      _counter++;
    }
    world.dragRotate.setMazeAngle(storedMoves[_counter][1]);
  }

  /// Resets the playback counter and cleared any recorded live moves.
  void resetPlayback() {
    _counter = 0;
    _recordedMovesLive.clear();
  }

  @override
  Future<void> reset() async {
    resetPlayback();
  }

  @override
  void start() {}

  @override
  void update(double dt) {
    _playbackAngles();
    super.update(dt);
  }
}
