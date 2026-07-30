import 'dart:async' as async;

import 'package:flame/components.dart';

import '../custom_game.dart';
import '../custom_world.dart';
import 'base_component.dart';
import 'ghost.dart';
import 'ghost_layer.dart';
import 'sprite_character.dart';

/// Manages the dynamic volume of the ghost siren sound based on ghost speed.
class GhostSiren extends BaseComponent
    with HasGameReference<CustomGame>, HasWorldReference<CustomWorld> {
  late final Ghosts ghosts = world.ghosts;
  late final List<Ghost> ghostList = ghosts.ghostList;

  async.Timer? _sirenTimer;

  /// Calculates the average speed of all ghosts currently in a normal state.
  double _averageGhostSpeed() {
    //test asserts below before call, else test here
    assert(game.isLive);
    assert(
      game.playState == PlayState.gaming ||
          game.playState == PlayState.playbackMode,
    );
    assert(!world.pacmans.isMounted || world.pacmans.anyAlivePacman);
    assert(!game.session.isWonOrLost);
    if (ghostList.isEmpty) {
      return 0;
    } else {
      return ghostList
              .map(
                (Ghost ghost) =>
                    ghost.current == CharacterState.normal ? ghost.speed : 0.0,
              ) //scared ghosts give zero which silences ghostsRoamingSiren
              .reduce((double value, double element) => value + element) /
          ghostList.length;
    }
  }

  /// Starts a periodic timer to update the siren volume based on ghost activity.
  async.Future<void> startSirenVolumeUpdaterTimer() async {
    final bool sirenEnabled = true;
    if (sirenEnabled) {
      if (!ghosts.isMounted) {
        return;
      }
      //test asserts below before call, else test here
      assert(!game.session.isWonOrLost);
      assert(game.isLive);
      assert(
        game.playState == PlayState.gaming ||
            game.playState == PlayState.playbackMode,
      );
      _sirenTimer ??= async.Timer.periodic(const Duration(milliseconds: 250), (
        async.Timer timer,
      ) {
        // timer cancelled already here
        assert(!game.session.isWonOrLost);
        assert(!world.pacmans.isMounted || world.pacmans.anyAlivePacman);
        assert(
          game.playState == PlayState.gaming ||
              game.playState == PlayState.playbackMode,
        );
        if (game.isLive) {
          game.audioController.siren.setVolume(
            _averageGhostSpeed() / game.level.levelSpeed,
            gradual: true,
          );
        } else {
          cancelSirenVolumeUpdaterTimer();
        }
      });
    }
  }

  /// Cancels the siren volume updater and silences the siren.
  void cancelSirenVolumeUpdaterTimer() {
    if (_sirenTimer != null) {
      game.audioController.siren.setVolume(0);
      _sirenTimer!.cancel();
      _sirenTimer = null;
      game.lifecycle.noteThatSomeRegularItemHasStopped();
    }
  }
}
