import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../maze.dart';
import 'game_character.dart';
import 'pacman.dart';
import 'wrapper_no_events.dart';

const multipleSpawningPacmans = false;

class Pacmans extends WrapperNoEvents {
  @override
  final priority = 2;

  final List<Pacman> pacmanList = [];

  final ValueNotifier<int> numberOfDeathsNotifier = ValueNotifier(0);
  final ValueNotifier<int> pacmanDyingNotifier = ValueNotifier(0);

  int numberAlivePacman() {
    if (pacmanList.isEmpty) {
      return 0;
    }
    return pacmanList
        .map((Pacman pacman) =>
            pacman.current != CharacterState.deadPacman ? 1 : 0)
        .reduce((value, element) => value + element);
  }

  void resetInstantAfterPacmanDeath() {
    assert(pacmanList.length == 1);
    Pacman dyingPacman = pacmanList[0];
    dyingPacman.setStartPositionAfterDeath();
  }

  @override
  void reset({bool mazeResize = false}) {
    if (multipleSpawningPacmans || mazeResize) {
      for (Pacman pacman in pacmanList) {
        pacman.disconnectFromBall(); //sync
        pacman.removeFromParent(); //async
      }
      add(Pacman(position: maze.pacmanStart));
    } else {
      if (pacmanList.isEmpty) {
        add(Pacman(position: maze.pacmanStart));
      } else {
        pacmanList[0].setStartPositionAfterDeath();
      }
    }
    numberOfDeathsNotifier.value = 0;
    pacmanDyingNotifier.value = 0;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    reset();
  }
}
