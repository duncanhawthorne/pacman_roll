import 'dart:async';

import 'package:flame/components.dart';

import '../../level_selection/levels.dart';
import '../game_screen.dart';
import '../custom_game.dart';
import 'base_component.dart';

/// Manages the display of tutorial instructions during specified levels.
class TutorialWrapper extends BaseComponent with HasGameReference<CustomGame> {
  bool _tutorialEverManuallyHidden = false;
  static const Duration _tutorialDelay = Duration(milliseconds: 3000);

  @override
  /// Initiates a delayed check to show the tutorial dialog if the user hasn't started playing.
  void start() {
    Future<void>.delayed(_tutorialDelay, () {
      if (!game.lifecycle.stopwatchStarted &&
          !_tutorialEverManuallyHidden &&
          game.level.number == Levels.levelToShowInstructions) {
        //if user hasn't worked out how to start by now, give a prompt
        game.overlays.add(GameScreen.tutorialDialogKey);
      }
    });
  }

  /// Hides the tutorial dialog and marks it as manually dismissed.
  void hide() {
    if (!_tutorialEverManuallyHidden && isMounted) {
      game.overlays.remove(GameScreen.tutorialDialogKey);
      _tutorialEverManuallyHidden = true;
    }
  }

  @override
  Future<void> reset() async {
    game.overlays.remove(GameScreen.tutorialDialogKey);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await reset();
  }
}
