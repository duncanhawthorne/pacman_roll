import 'dart:async';

import 'package:flame/components.dart';

import '../../level_selection/levels.dart';
import '../game_screen.dart';
import '../pacman_game.dart';
import 'wrapper_no_events.dart';

class TutorialWrapper extends WrapperNoEvents
    with HasGameReference<PacmanGame> {
  bool _tutorialEverManuallyHidden = false;
  static const Duration _tutorialDelay = Duration(milliseconds: 3000);

  @override
  void start() {
    Future<void>.delayed(_tutorialDelay, () {
      if (!game.stopwatchStarted &&
          !_tutorialEverManuallyHidden &&
          game.level.number == Levels.levelToShowInstructions) {
        //if user hasn't worked out how to start by now, give a prompt
        game.overlays.add(GameScreen.tutorialDialogKey);
      }
    });
  }

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
