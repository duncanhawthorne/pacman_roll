import 'dart:async';

import 'package:flame/components.dart';

import '../game_screen.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'wrapper_no_events.dart';

class TutorialWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final priority = 100;

  bool _tutorialEverManuallyHidden = false;
  static const tutorialDelay = Duration(milliseconds: 3000);

  @override
  void start() {
    Future.delayed(tutorialDelay, () {
      if (!game.levelStarted &&
          !_tutorialEverManuallyHidden &&
          world.level.number == 1) {
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
  void reset() {
    game.overlays.remove(GameScreen.tutorialDialogKey);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    reset();
  }
}
