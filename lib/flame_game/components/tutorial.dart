import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../style/palette.dart';
import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'wrapper_no_events.dart';

class TutorialWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final priority = 100;

  bool _mazeEverRotated = false;

  @override
  void start() {
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!game.levelStarted &&
          !_mazeEverRotated &&
          game.findByKey(ComponentKey.named('tutorial')) == null &&
          world.level.number == 1) {
        //if user hasn't worked out how to start by now, give a prompt
        add(
          TextComponent(
              text: '←←←←←←←←\n↓      ↑\n↓ Drag ↑\n↓      ↑\n→→→→→→→→',
              position: maze.cage,
              anchor: Anchor.center,
              textRenderer: _tutorialTextRenderer,
              key: ComponentKey.named('tutorial'),
              priority: 100),
        );
      }
    });
  }

  @override
  void reset() {
    if (!_mazeEverRotated) {
      if (game.findByKey(ComponentKey.named('tutorial')) != null) {
        game.findByKey(ComponentKey.named('tutorial'))!.removeFromParent();
      }
      _mazeEverRotated = true;
    }
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
