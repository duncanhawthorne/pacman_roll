import 'package:flame/components.dart';

import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'wrapper_no_events.dart';

class WallBlockingWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final priority = 1000;

  @override
  void reset() {
    if (children.isNotEmpty) {
      removeAll(children);
    }
    addAll(maze.mazeBlockingWalls());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    reset();
  }
}
