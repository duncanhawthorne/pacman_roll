import 'dart:async';

import 'package:flame/components.dart';

import '../maze/maze.dart';
import 'base_component.dart';

/// A container component for static visual boundaries at the edges of the maze.
class BlockingBarWrapper extends BaseComponent with CustomTraversal, Snapshot {
  @override
  final int priority = 1000;
  int _mazeIdLast = -100;

  @override
  Future<void> reset() async {
    if (maze.mazeId == _mazeIdLast) {
      return;
    }
    _mazeIdLast = maze.mazeId;
    if (children.isNotEmpty) {
      removeAll(children);
    }
    addAll(maze.itemFactory.blockingWalls());
    clearSnapshot();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await reset();
  }

  @override
  void updateSubtree(double dt) {
    // no point traversing large list of children as nothing to update
    // so cut short the updateTree here
    //super.updateTree(dt);
  }
}
