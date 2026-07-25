import 'dart:async';

import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../../utils/helper.dart';
import '../custom_game.dart';
import '../custom_world.dart';
import '../effects/remove_effects.dart';
import 'base_component.dart';
import 'game_character.dart';
import 'ghost.dart';
import 'ghost_siren.dart';
import 'sprite_character.dart';

const int _kGhostScaredTimeMillis = 6000;

/// A container component that manages all active ghosts in the game.
class Ghosts extends BaseComponent
    with HasWorldReference<CustomWorld>, HasGameReference<CustomGame> {
  @override
  final int priority = 1;

  /// List of all active ghosts managed by this layer.
  final List<Ghost> ghostList = <Ghost>[];

  /// Shared character state for all ghosts (e.g., Normal, Scared).
  CharacterState current = CharacterState.normal;
  Timer _ghostsScaredTimer = Timer(0); //length set in reset
  SpawnComponent? _ghostSpawner;

  /// Helper to manage the ghost siren sound effects.
  final GhostSiren ghostSiren = GhostSiren();

  /// Adds initial ghosts to the maze based on level configuration.
  void _addThreeGhosts() {
    assert(ghostList.isEmpty);
    final List<int> positions = game.level.numStartingGhosts == 3
        ? <int>[0, 1, 2]
        : game.level.numStartingGhosts == 2
        ? <int>[0, 2]
        : <int>[1];
    for (int i = 0; i < game.level.numStartingGhosts; i++) {
      add(Ghost(ghostID: positions[i]));
    }
  }

  /// Changes the state of all ghosts to "scared" and starts the scared timer.
  void scareGhosts() {
    if (!isMounted) {
      return;
    }
    current = CharacterState.scared;
    if (!game.session.isWonOrLost) {
      game.audioController.playSfx(SfxType.ghostsScared);
      for (final Ghost ghost in ghostList) {
        ghost.setScared();
      }
      _ghostsScaredTimer.start();
    }
  }

  /// Enables the continuous spawning of bonus ghosts during gameplay.
  void addSpawner() {
    if (!isMounted) {
      return; //else cant use game references
    }
    assert(!game.session.isWonOrLost); //test before call, else test here
    if (game.level.multipleSpawningGhosts) {
      _ghostSpawner ??= SpawnComponent(
        factory: (int i) => Ghost(ghostID: <int>[3, 4, 5][random.nextInt(3)]),
        selfPositioning: true,
        period: game.level.ghostSpawnTimerLength.toDouble(),
      );
      if (!_ghostSpawner!.isMounted) {
        add(_ghostSpawner!);
      }
    }
  }

  /// Disables spawning and cleans up the spawner component.
  void removeSpawner() {
    if (!isMounted) {
      return; //else cant use game references
    }
    _ghostSpawner?.removeFromParent();
    _ghostSpawner = null; //FIXME shouldn't be necessary
    _ghostSpawner?.timer.reset(); //so next spawn based on time of reset
    game.lifecycle.noteThatSomeRegularItemHasStopped();
  }

  void _removeAllGhosts() {
    //create a new list toList so can iterate and remove simultaneously
    for (final Ghost ghost in ghostList.toList()) {
      ghost.removeFromParent();
    }
    removeSpawner();
  }

  /// Disconnects ghosts from their physical bodies, effectively freezing them.
  void disconnectGhostsFromBalls() {
    for (final Ghost ghost in ghostList) {
      removeEffects(ghost);
      ghost.setPhysicsState(PhysicsState.none); //sync
    }
  }

  /// Starts periodic ghost activities like spawning and sound effects.
  void startRegularItems() {
    addSpawner();
    ghostSiren.startSirenVolumeUpdaterTimer();
  }

  /// Stops periodic ghost activities.
  void stopRegularItems() {
    removeSpawner();
    ghostSiren.cancelSirenVolumeUpdaterTimer();
  }

  /// Cleans up ghosts and resets state after the player wins.
  void resetAfterGameWin() {
    game.audioController.stopSound(SfxType.ghostsScared);
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
        game.audioController.stopSound(SfxType.ghostsScared);
      }
    }
  }

  @override
  Future<void> reset({bool mazeResize = false}) async {
    unawaited(game.audioController.stopSound(SfxType.ghostsScared));
    ghostSiren.cancelSirenVolumeUpdaterTimer();
    current = CharacterState.normal;
    _ghostsScaredTimer.pause(); //makes update function for timer free
    _removeAllGhosts();
    _ghostSpawner = null; //so will reflect new level parameters
    _ghostsScaredTimer = Timer(
      _kGhostScaredTimeMillis / game.level.ghostScaredTimeFactor / 1000,
    );
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
    add(ghostSiren);
    await reset();
  }
}
