import 'dart:core';

import 'package:flame/components.dart';

import '../maze.dart';
import 'game_character.dart';
import 'ghost.dart';
import 'pacman.dart';

class PacmanClone extends Pacman with Clone {
  PacmanClone(
      {required Vector2 super.position, required Pacman super.original});
}

class GhostClone extends Ghost with Clone {
  GhostClone({required super.ghostID, required Ghost super.original});
}

mixin Clone on GameCharacter {
  @override
  // ignore: overridden_fields
  final bool connectedToBall = false;

  void updateCloneFrom(GameCharacter original) {
    assert(isClone);
    position
      ..setFrom(original.position)
      ..x -= maze.mazeWidth * position.x.sign; //mirror on other side
    angle = original.angle;
    current = original.current;
  }

  @override
  void update(double dt) {
    assert(isClone); //i.e. no cascade of clones
    updateCloneFrom(original!);
    super.update(dt); // must call to have sprite animations
  }
}
