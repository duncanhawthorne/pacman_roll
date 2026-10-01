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
    with HasGameRef<CustomGame>, HasWorldRef<CustomWorld> {
  static const bool _slideCharactersAfterPacmanDeath = true;

  /// Initiates the reset process after Pacman dies.
  void resetAfterPacmanDeath(Pacman dyingPacman) {
    _resetSlideAfterPacmanDeath(dyingPacman);
  }

  /// Resets the positions of characters with a sliding animation if enabled.
  void _resetSlideAfterPacmanDeath(Pacman dyingPacman) {
    //reset ghost scared status. Shouldn't be relevant as just died
    gameRef.audioController.stopSound(SfxType.ghostsScared);
    if (!gameRef.session.isWonOrLost) {
      if (_slideCharactersAfterPacmanDeath) {
        worldRef.dragRotate.resetSlide(_resetInstantAfterPacmanDeath);
        dyingPacman.resetSlideAfterDeath();
        worldRef.ghosts.resetSlideAfterPacmanDeath();
      } else {
        _resetInstantAfterPacmanDeath();
      }
    } else {
      _resetFlourishState();
    }
  }

  /// Performs an instant reset of the characters and game state.
  void _resetInstantAfterPacmanDeath() {
    if (gameRef.playState == PlayState.flourish) {
      if (gameRef.level.infLives) {
        gameRef.session.numberOfDeathsNotifier.value = 0;
        worldRef.pacmans.pacmanDyingNotifier.value = 0;
      }
      worldRef.pacmans.resetInstantAfterPacmanDeath();
      worldRef.ghosts.resetInstantAfterPacmanDeath();
      worldRef.dragRotate.reset();
      worldRef.autoPauser.reset();
      _resetFlourishState();
      if (gameRef.playState == PlayState.playbackMode) {
        gameRef.reset();
      }
    }
  }

  /// Transitions the game state from flourish to unflourish.
  void _resetFlourishState() {
    if (gameRef.playState == PlayState.flourish) {
      gameRef.playState = PlayState.unflourish;
    }
  }

  @override
  Future<void> reset() async {
    _resetFlourishState();
  }
}
