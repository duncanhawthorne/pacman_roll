import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../audio/sounds.dart';
import '../../firebase/firebase_saves.dart';
import '../../utils/helper.dart';
import '../../utils/string_helper.dart';
import '../components/base_component.dart';
import '../custom_game.dart';
import '../custom_world.dart';
import '../game_screen.dart';
import '../maze/maze.dart';

/// Manages the current game session's state, including scoring, winning, and losing.
///
/// Tracks the number of deaths, items remaining, and game time.
class GameSession extends BaseComponent
    with HasWorldRef<CustomWorld>, HasGameRef<CustomGame> {
  String _userString = "";

  static const int _deathPenaltyMillis = 5000;

  int get _deathPenalty => (gameRef.level.isTutorial
      ? 0
      : min(gameRef.level.maxAllowedDeaths - 1, numberOfDeathsNotifier.value) *
            _deathPenaltyMillis);

  /// Returns the current game time in milliseconds, including death penalties.
  int get stopwatchMilliSeconds =>
      (gameRef.lifecycle.stopwatch.current * 1000).toInt() + _deathPenalty;

  /// Returns true if the player has won the game (all items collected).
  bool get _isWon => worldRef.pellets.winState;

  /// Returns true if the player has lost the game (exceeded max allowed deaths).
  bool get _isLost =>
      numberOfDeathsNotifier.value >= gameRef.level.maxAllowedDeaths;

  /// Returns true if the game is over, either by winning or losing.
  bool get isWonOrLost => _isWon || _isLost;

  VoidCallback? _deathsListenerRef;
  VoidCallback? _itemsListenerRef;

  /// Notifies listeners when the number of deaths changes.
  final ValueNotifier<int> numberOfDeathsNotifier = ValueNotifier<int>(0);

  /// Notifies listeners when the number of items remaining changes.
  late final ValueNotifier<int> itemsRemainingNotifier =
      worldRef.pellets.pelletsRemainingNotifier;

  /// Gathers relevant state for saving or uploading scores.
  Map<String, Object> _getCurrentGameState() {
    final Map<String, Object> gameStateTmp = <String, Object>{};
    gameStateTmp["userString"] = _userString;
    gameStateTmp["levelNum"] = gameRef.level.number;
    gameStateTmp["levelCompleteTime"] = stopwatchMilliSeconds;
    gameStateTmp["dateTime"] = DateTime.now().millisecondsSinceEpoch;
    gameStateTmp["mazeId"] = maze.mazeId;
    return gameStateTmp;
  }

  /// Sets up listeners to monitor win/loss conditions.
  void _winOrLoseGameListener() {
    assert(!gameRef.lifecycle.stopwatchStarted); //so no instant trigger
    _deathsListenerRef = () {
      if (_isLost &&
          gameRef.lifecycle.stopwatchStarted &&
          gameRef.playState != PlayState.playbackMode) {
        _handleLoseGame();
      }
    };
    _itemsListenerRef = () {
      if (_isWon &&
          gameRef.lifecycle.stopwatchStarted &&
          gameRef.playState != PlayState.playbackMode) {
        _handleWinGame();
      }
    };
    numberOfDeathsNotifier.addListener(_deathsListenerRef!);
    itemsRemainingNotifier.addListener(_itemsListenerRef!);
  }

  /// Handles the game win state, including playing music and saving progress.
  void _handleWinGame() {
    assert(!isRemoving);
    assert(isWonOrLost);
    assert(gameRef.lifecycle.stopwatchStarted);
    assert(!(gameRef.playState == PlayState.playbackMode));
    worldRef.mouseMove.exitPointerLock();
    gameRef.lifecycle.stopRegularItems();
    gameRef.audioController.play(SfxType.endMusic);
    worldRef.ghosts.resetAfterGameWin();
    const int minRecordableWinTimeMillis = 10 * 1000;
    if (stopwatchMilliSeconds > minRecordableWinTimeMillis &&
        !gameRef.level.isTutorial) {
      fBase.firebasePushSingleScore(_userString, _getCurrentGameState());
    }
    gameRef.playerProgress.saveLevelComplete(_getCurrentGameState());
    gameRef.dialogs.switchTo(GameScreen.wonDialogKey);
  }

  /// Handles the game lose state, including stopping sounds and showing the lose dialog.
  void _handleLoseGame() {
    assert(!isRemoving);
    assert(isWonOrLost);
    assert(gameRef.lifecycle.stopwatchStarted);
    worldRef.mouseMove.exitPointerLock();
    gameRef.lifecycle.stopRegularItems();
    gameRef.audioController.stopAllSounds();
    gameRef.dialogs.switchTo(GameScreen.loseDialogKey);
  }

  @override
  Future<void> reset() async {
    _userString = getRandomString(random, 15);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _winOrLoseGameListener(); //isn't disposed so run once, not on start()
  }

  @override
  Future<void> onRemove() async {
    if (_deathsListenerRef != null) {
      numberOfDeathsNotifier.removeListener(_deathsListenerRef!);
    }
    if (_itemsListenerRef != null) {
      itemsRemainingNotifier.removeListener(_itemsListenerRef!);
    }
    super.onRemove();
  }
}
