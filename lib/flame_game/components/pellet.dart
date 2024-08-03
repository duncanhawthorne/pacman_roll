import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../maze.dart';
import '../pacman_world.dart';
import 'mini_pellet.dart';

class Pellet extends CircleComponent
    with HasWorldReference<PacmanWorld>, IgnoreEvents {
  Pellet({required super.position, double radiusFactor = 1})
      : super(
            radius:
                maze.spriteWidth() / 2 * Maze.pelletScaleFactor * radiusFactor,
            anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox(
      isSolid: true,
      collisionType: CollisionType.passive,
      radius: this is MiniPellet ? 0 : radius / 2,
      position: Vector2.all(radius),
      anchor: Anchor.center,
    ));
    //debugMode = true;
    world.pelletsRemainingNotifier.value += 1;
  }

  @override
  Future<void> onRemove() async {
    world.pelletsRemainingNotifier.value -= 1;
    super.onRemove();
  }
}
