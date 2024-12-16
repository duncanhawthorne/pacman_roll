import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../maze.dart';
import 'game_character.dart';
import 'pacman.dart';
import 'wrapper_no_events.dart';

class Pacmans extends WrapperNoEvents {
  @override
  final int priority = 2;

  final List<Pacman> pacmanList = <Pacman>[];

  final ValueNotifier<int> numberOfDeathsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> pacmanDyingNotifier = ValueNotifier<int>(0);

  bool get pacmanDeathIsFinalPacman =>
      !multipleSpawningPacmans || pacmanList.length == 1 || !anyAlivePacman;

  Vector2 get ghostHomingTarget => pacmanList[0].position;

  bool get anyAlivePacman => pacmanList
      .where((Pacman pacman) => pacman.current != CharacterState.dead)
      .isNotEmpty;

  void resetInstantAfterPacmanDeath() {
    assert(pacmanList.length == 1);
    pacmanList[0].resetInstantAfterDeath(); //dying pacman
  }

  @override
  Future<void> reset({bool mazeResize = false}) async {
    for (final Pacman pacman in pacmanList) {
      pacman.removeFromParent();
    }
    add(Pacman(position: maze.pacmanStart));
    numberOfDeathsNotifier.value = 0;
    pacmanDyingNotifier.value = 0;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    unawaited(reset());
  }
}
