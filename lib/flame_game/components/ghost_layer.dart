import 'dart:async' as async;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/foundation.dart';

import '../../audio/sounds.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'game_character.dart';
import 'ghost.dart';
import 'wrapper_no_events.dart';

final bool _iOSWeb = defaultTargetPlatform == TargetPlatform.iOS && kIsWeb;
final bool _sirenEnabled = !_iOSWeb;

class Ghosts extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final priority = 1;

  async.Timer? _ghostTimer;
  async.Timer? _sirenTimer;

  final List<Ghost> ghostList = [];

  int scaredTimeLatest = 0;

  double _averageGhostSpeed() {
    if (!game.isGameLive ||
        world.pacmans.numberAlivePacman() == 0 ||
        world.gameWonOrLost ||
        ghostList.isEmpty) {
      return 0;
    } else {
      return ghostList
              .map((Ghost ghost) =>
                  ghost.current == CharacterState.normal ? ghost.speed : 0.0)
              .reduce((value, element) => value + element) /
          ghostList.length;
    }
  }

  void sirenVolumeUpdatedTimer() async {
    // ignore: prefer_conditional_assignment
    if (_sirenEnabled) {
      if (_sirenTimer == null && game.isGameLive && !world.gameWonOrLost) {
        _sirenTimer =
            async.Timer.periodic(const Duration(milliseconds: 250), (timer) {
          if (game.isGameLive &&
              !world.gameWonOrLost &&
              !world.doingLevelResetFlourish) {
            game.audioController.setSirenVolume(
                _averageGhostSpeed() * flameGameZoom / 30,
                gradual: true);
          } else {
            game.audioController.setSirenVolume(0);
            timer.cancel();
            _sirenTimer = null;
          }
        });
      }
    }
  }

  void _cancelSirenVolumeUpdatedTimer() {
    if (_sirenTimer != null) {
      game.audioController.setSirenVolume(0);
      _sirenTimer!.cancel();
      _sirenTimer = null;
    }
  }

  void _addThreeGhosts() {
    for (int i = 0; i < 3; i++) {
      add(Ghost(idNum: i));
    }
  }

  void scareGhosts() {
    if (world.pellets.pelletsRemainingNotifier.value != 0) {
      world.play(SfxType.ghostsScared);
      for (Ghost ghost in ghostList) {
        ghost.setScared();
      }
      scaredTimeLatest = game.now;
    }
  }

  void startMultiGhostAdderTimer() {
    if (game.level.multipleSpawningGhosts &&
        _ghostTimer == null &&
        game.isGameLive &&
        !world.gameWonOrLost) {
      _ghostTimer = async.Timer.periodic(
          Duration(milliseconds: world.level.ghostSpwanTimerLength * 1000),
          (timer) {
        if (game.isGameLive &&
            !world.gameWonOrLost &&
            !world.doingLevelResetFlourish) {
          add(Ghost(idNum: [3, 4, 5][game.random.nextInt(3)]));
        } else {
          timer.cancel();
          _ghostTimer = null;
        }
      });
    }
  }

  void cancelMultiGhostAdderTimer() {
    if (world.level.multipleSpawningGhosts && _ghostTimer != null) {
      _ghostTimer!.cancel();
      _ghostTimer = null;
    }
  }

  void _trimAllGhosts() {
    for (Ghost ghost in ghostList) {
      ghost.removeWhere((item) => item is Effect); //sync
      ghost.disconnectFromBall(); //sync
      ghost.removeFromParent(); //async
    }
  }

  void disconnectGhostsFromBalls() {
    for (Ghost ghost in ghostList) {
      ghost.removeWhere((item) => item is Effect);
      ghost.disconnectFromBall(); //sync
    }
  }

  void resetAfterGameWin() {
    scaredTimeLatest = 0;
    _trimAllGhosts();
  }

  void resetSlideAfterPacmanDeath() {
    scaredTimeLatest = 0;
    for (Ghost ghost in ghostList) {
      ghost.resetSlideAfterPacmanDeath();
    }
  }

  void resetInstantAfterPacmanDeath() {
    scaredTimeLatest = 0;
    if (game.level.multipleSpawningGhosts) {
      _trimAllGhosts();
      _addThreeGhosts();
    } else {
      for (Ghost ghost in ghostList) {
        ghost.resetInstantAfterPacmanDeath();
      }
    }
  }

  @override
  void reset({bool mazeResize = false}) {
    cancelMultiGhostAdderTimer();
    _cancelSirenVolumeUpdatedTimer;
    scaredTimeLatest = 0;
    _trimAllGhosts();
    _addThreeGhosts();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    reset();
  }
}
