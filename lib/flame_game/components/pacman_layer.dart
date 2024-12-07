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

  int numberAlivePacman() {
    if (pacmanList.isEmpty) {
      return 0;
    }
    return pacmanList
        .map((Pacman pacman) => pacman.current != CharacterState.dead ? 1 : 0)
        .reduce((int value, int element) => value + element);
  }

  void resetInstantAfterPacmanDeath() {
    assert(pacmanList.length == 1);
    pacmanList[0].resetInstantAfterDeath(); //dying pacman
  }

  @override
  void reset({bool mazeResize = false}) {
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
    reset();
  }
}
