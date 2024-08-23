import 'dart:core';

import '../maze.dart';
import 'game_character.dart';
import 'ghost.dart';
import 'pacman.dart';

class PacmanClone extends Pacman with Clone {
  PacmanClone({required super.position, required super.original});
}

class GhostClone extends Ghost with Clone {
  GhostClone(
      {required position, required super.idNum, required super.original});
}

mixin Clone on GameCharacter {
  @override
  // ignore: overridden_fields
  final connectedToBall = false;

  void updateCloneFrom(GameCharacter original) {
    assert(isClone);
    position.setFrom(original.position);
    position.x -= maze.mazeWidth * position.x.sign;
    angle = original.angle;
    current = original.current;
  }

  @override
  void update(double dt) {
    assert(clone == null); //i.e. no cascade of clones
    updateCloneFrom(original!);
    super.update(dt); // must call to have sprite animations
  }

  @override
  Future<void> onLoad() async {
    //animations = await _getAnimations(); //dont need this. done on gameresize
    //don't call super
    add(hitbox);
  }

  @override
  Future<void> onRemove() async {
    //don't call super
  }
}
