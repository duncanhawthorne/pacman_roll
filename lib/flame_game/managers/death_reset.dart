import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../components/base_component.dart';
import '../components/pacman.dart';
import '../custom_game.dart';
import '../custom_world.dart';

/// Manages the reset logic when Pacman dies.
///
/// This includes stopping sounds, sliding characters back to their start
/// positions, and resetting the game state.
class DeathReset extends BaseComponent
    with HasGameReference<CustomGame>, HasWorldReference<CustomWorld> {
  static const bool _slideCharactersAfterPacmanDeath = true;

  /// Initiates the reset process after Pacman dies.
  void resetAfterPacmanDeath(Pacman dyingPacman) {
    _resetSlideAfterPacmanDeath(dyingPacman);
  }

  /// Resets the positions of characters with a sliding animation if enabled.
  void _resetSlideAfterPacmanDeath(Pacman dyingPacman) {
    //reset ghost scared status. Shouldn't be relevant as just died
    game.audioController.stopSound(SfxType.ghostsScared);
    if (!game.session.isWonOrLost) {
      if (_slideCharactersAfterPacmanDeath) {
        world.dragRotate.resetSlide(_resetInstantAfterPacmanDeath);
        dyingPacman.resetSlideAfterDeath();
        world.ghosts.resetSlideAfterPacmanDeath();
      } else {
        _resetInstantAfterPacmanDeath();
      }
    } else {
      _resetFlourishState();
    }
  }

  /// Performs an instant reset of the characters and game state.
  void _resetInstantAfterPacmanDeath() {
    if (game.playState == PlayState.flourish) {
      if (game.level.infLives) {
        game.session.numberOfDeathsNotifier.value = 0;
        world.pacmans.pacmanDyingNotifier.value = 0;
      }
      world.pacmans.resetInstantAfterPacmanDeath();
      world.ghosts.resetInstantAfterPacmanDeath();
      world.dragRotate.reset();
      world.autoPauser.reset();
      _resetFlourishState();
      if (game.playState == PlayState.playbackMode) {
        game.reset();
      }
    }
  }

  /// Transitions the game state from flourish to unflourish.
  void _resetFlourishState() {
    if (game.playState == PlayState.flourish) {
      game.playState = PlayState.unflourish;
    }
  }

  @override
  Future<void> reset() async {
    _resetFlourishState();
  }
}
