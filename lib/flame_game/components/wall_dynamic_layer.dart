import 'dart:async';

import '../maze/maze.dart';
import 'base_component.dart';

/// A container component for dynamic, physics-affected walls.
class MovingWallWrapper extends BaseComponent {
  @override
  Future<void> reset() async {
    if (children.isNotEmpty) {
      removeAll(children);
    }
    addAll(maze.physicsFactory.movingWalls());
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await reset();
  }
}
