import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../style/palette.dart';
import '../game_screen.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'wrapper_no_events.dart';

class TutorialWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final priority = 100;

  bool _tutorialEverManuallyHidden = false;

  final tutorialComponent = TextComponent(
      text: '←←←←←←←←\n↓      ↑\n↓ Drag ↑\n↓      ↑\n→→→→→→→→',
      position: Vector2.zero(),
      anchor: Anchor.center,
      textRenderer: _tutorialTextRenderer,
      key: ComponentKey.named('tutorial'),
      priority: 100);

  @override
  void start() {
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!game.levelStarted &&
          !_tutorialEverManuallyHidden &&
          game.findByKey(ComponentKey.named('tutorial')) == null &&
          world.level.number == 1) {
        //if user hasn't worked out how to start by now, give a prompt
        //add(tutorialComponent);
        game.overlays.add(GameScreen.tutorialDialogKey);
      }
    });
  }

  void hide() {
    if (!_tutorialEverManuallyHidden && isMounted) {
      //tutorialComponent.removeFromParent();
      game.overlays.remove(GameScreen.tutorialDialogKey);
      _tutorialEverManuallyHidden = true;
    }
  }

  @override
  void reset() {
    //tutorialComponent.removeFromParent();
    game.overlays.remove(GameScreen.tutorialDialogKey);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    reset();
  }
}

final TextPaint _tutorialTextRenderer = TextPaint(
  style: const TextStyle(
    backgroundColor: Palette.blueMaze,
    fontSize: 3,
    color: Palette.playSessionContrast,
    fontFamily: 'Press Start 2P',
  ),
);
