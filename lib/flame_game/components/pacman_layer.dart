import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../maze/maze.dart';
import '../custom_game.dart';
import 'base_component.dart';
import 'pacman.dart';
import 'sprite_character.dart';

/// A container component that manages all Pacman instances in the game.
class Pacmans extends BaseComponent with HasGameReference<CustomGame> {
  @override
  final int priority = 2;

  final List<Pacman> pacmanList = <Pacman>[];

  final ValueNotifier<int> pacmanDyingNotifier = ValueNotifier<int>(0);

  bool get pacmanDeathIsFinalPacman =>
      !multipleSpawningPacmans || pacmanList.length == 1 || !anyAlivePacman;

  /// Returns the target position for ghosts when they are in a homing state.
  Vector2 get ghostHomingTarget => pacmanList.isNotEmpty
      ? pacmanList[0].position
      : maze.dimensions.pacmanStart;

  /// Checks if there are any Pacman instances currently alive.
  bool get anyAlivePacman =>
      pacmanList.any((Pacman pacman) => pacman.current != CharacterState.dead);

  /// Instantly resets the primary Pacman instance after a death.
  void resetInstantAfterPacmanDeath() {
    assert(pacmanList.length == 1);
    pacmanList[0].resetInstantAfterDeath(); //dying pacman
  }

  @override
  Future<void> reset({bool mazeResize = false}) async {
    //create a new list toList so can iterate and remove simultaneously
    for (final Pacman pacman in pacmanList.toList()) {
      pacman.removeFromParent();
    }
    add(Pacman(position: maze.dimensions.pacmanStart));
    game.session.numberOfDeathsNotifier.value = 0;
    pacmanDyingNotifier.value = 0;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await reset();
  }
}
