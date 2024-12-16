import 'dart:async' as async;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../audio/sounds.dart';
import '../effects/remove_effects.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'game_character.dart';
import 'ghost.dart';
import 'wrapper_no_events.dart';

final bool _iOSWeb = defaultTargetPlatform == TargetPlatform.iOS && kIsWeb;
final bool _sirenEnabled = !_iOSWeb;
const int _kGhostScaredTimeMillis = 6000;

class Ghosts extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final int priority = 1;

  final List<Ghost> ghostList = <Ghost>[];

  CharacterState current = CharacterState.normal;
  Timer _ghostsScaredTimer = Timer(0); //length set in reset
  SpawnComponent? _ghostSpawner;
  async.Timer? _sirenTimer;

  bool get ghostsLoaded => ghostList.isNotEmpty && ghostList[0].isLoaded;

  double _averageGhostSpeed() {
    assert(game.isLive); //test before call, else test here
    assert(game.openingScreenCleared);
    assert(world.pacmans.anyAlivePacman); //test before call, else test here
    assert(!game.isWonOrLost); //test before call, else test here
    if (ghostList.isEmpty) {
      return 0;
    } else {
      return ghostList
              .map((Ghost ghost) =>
                  ghost.current == CharacterState.normal ? ghost.speed : 0.0)
              .reduce((double value, double element) => value + element) /
          ghostList.length;
    }
  }

  async.Future<void> sirenVolumeUpdaterTimer() async {
    if (_sirenEnabled) {
      if (!isMounted) {
        return;
      }
      assert(!game.isWonOrLost); //test before call, else test here
      assert(game.isLive); //test before call, else test here
      assert(game.openingScreenCleared);
      _sirenTimer ??= async.Timer.periodic(const Duration(milliseconds: 250),
          (async.Timer timer) {
        assert(!game.isWonOrLost); //timer cancelled already here
        assert(world.pacmans.anyAlivePacman); //timer cancelled already here
        assert(!world.doingLevelResetFlourish); //timer cancelled already here
        assert(game.openingScreenCleared);
        if (game.isLive) {
          game.audioController.setSirenVolume(
              _averageGhostSpeed() * flameGameZoom / 30,
              gradual: true);
        } else {
          cancelSirenVolumeUpdaterTimer();
        }
      });
    }
  }

  void cancelSirenVolumeUpdaterTimer() {
    if (_sirenTimer != null) {
      game.audioController.setSirenVolume(0);
      _sirenTimer!.cancel();
      _sirenTimer = null;
    }
  }

  void _addThreeGhosts() {
    final List<int> positions = game.level.numStartingGhosts == 3
        ? <int>[0, 1, 2]
        : game.level.numStartingGhosts == 2
            ? <int>[0, 2]
            : <int>[1];
    for (int i = 0; i < game.level.numStartingGhosts; i++) {
      add(Ghost(ghostID: positions[i]));
    }
  }

  void scareGhosts() {
    if (!isMounted) {
      return;
    }
    current = CharacterState.scared;
    if (world.pellets.pelletsRemainingNotifier.value != 0) {
      world.play(SfxType.ghostsScared);
      for (final Ghost ghost in ghostList) {
        ghost.setScared();
      }
      _ghostsScaredTimer.start();
    }
  }

  void addSpawner() {
    if (!isMounted) {
      return; //else cant use game references
    }
    assert(!game.isWonOrLost); //test before call, else test here
    if (game.level.multipleSpawningGhosts) {
      _ghostSpawner ??= SpawnComponent(
        factory: (int i) =>
            Ghost(ghostID: <int>[3, 4, 5][game.random.nextInt(3)]),
        selfPositioning: true,
        period: game.level.ghostSpawnTimerLength.toDouble(),
      );
      if (!_ghostSpawner!.isMounted) {
        add(_ghostSpawner!);
      }
    }
  }

  void removeSpawner() {
    if (!isMounted) {
      return; //else cant use game references
    }
    _ghostSpawner?.removeFromParent();
    _ghostSpawner = null; //FIXME shouldn't be necessary
    _ghostSpawner?.timer.reset(); //so next spawn based on time of reset
  }

  void _removeAllGhosts() {
    for (final Ghost ghost in ghostList) {
      ghost.removeFromParent();
    }
    removeSpawner();
  }

  void disconnectGhostsFromBalls() {
    for (final Ghost ghost in ghostList) {
      removeEffects(ghost);
      ghost.disconnectFromBall(); //sync
    }
  }

  void resetAfterGameWin() {
    current = CharacterState.normal;
    _ghostsScaredTimer.pause(); //makes update function for timer free
    _removeAllGhosts();
  }

  void resetSlideAfterPacmanDeath() {
    current = CharacterState.normal;
    _ghostsScaredTimer.pause(); //makes update function for timer free
    for (final Ghost ghost in ghostList) {
      ghost.resetSlideAfterPacmanDeath();
    }
  }

  void resetInstantAfterPacmanDeath() {
    current = CharacterState.normal;
    _ghostsScaredTimer.pause(); //makes update function for timer free
    if (game.level.multipleSpawningGhosts) {
      _removeAllGhosts();
      _addThreeGhosts();
    } else {
      for (final Ghost ghost in ghostList) {
        ghost.resetInstantAfterPacmanDeath();
      }
      //no spawner to remove
    }
  }

  static const double _scaredToScaredIshThreshold = 2 / 3;
  void _stateSequence(double dt) {
    _ghostsScaredTimer.update(dt);
    if (current == CharacterState.scared) {
      if (_ghostsScaredTimer.current >
          _scaredToScaredIshThreshold * _ghostsScaredTimer.limit) {
        current = CharacterState.scaredIsh;
        for (final Ghost ghost in ghostList) {
          ghost.setScaredToScaredIsh();
        }
      }
    }
    if (current == CharacterState.scaredIsh) {
      if (_ghostsScaredTimer.finished) {
        current = CharacterState.normal;
        for (final Ghost ghost in ghostList) {
          ghost.setScaredIshToNormal();
        }
        _ghostsScaredTimer.pause(); //makes update function for timer free
        game.audioController.stopSfx(SfxType.ghostsScared);
      }
    }
  }

  @override
  Future<void> reset({bool mazeResize = false}) async {
    cancelSirenVolumeUpdaterTimer();
    current = CharacterState.normal;
    _ghostsScaredTimer.pause(); //makes update function for timer free
    _removeAllGhosts();
    _ghostSpawner = null; //so will reflect new level parameters
    _ghostsScaredTimer = Timer(
        _kGhostScaredTimeMillis / game.level.ghostScaredTimeFactor / 1000);
    _addThreeGhosts();
  }

  @override
  void update(double dt) {
    _stateSequence(dt);
    super.update(dt);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    async.unawaited(reset());
  }
}
