import 'dart:async';

import 'package:flame/components.dart';

import '../maze.dart';
import '../pacman_game.dart';
import 'wrapper_no_events.dart';

class WallWrapper extends WrapperNoEvents
    with HasGameReference<PacmanGame>, Snapshot {
  int _mazeIdLast = -100;

  @override
  Future<void> reset() async {
    if (game.mazeId == _mazeIdLast) {
      return;
    }
    _mazeIdLast = game.mazeId;
    if (children.isNotEmpty) {
      removeAll(children);
    }
    await addAll(maze.mazeWalls());
    clearSnapshot();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await reset();
  }

  @override
  void updateTree(double dt) {
    // no point traversing large list of children as nothing to update
    // so cut short the updateTree here
    //super.updateTree(dt);
  }
}
