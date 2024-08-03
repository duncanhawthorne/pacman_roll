import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../maze.dart';
import '../pacman_world.dart';

class Pellet extends CircleComponent
    with HasWorldReference<PacmanWorld>, IgnoreEvents {
  Pellet(
      {required super.position, double radiusFactor = 1, this.hitBoxFactor = 1})
      : super(
            radius:
                maze.spriteWidth() / 2 * Maze.pelletScaleFactor * radiusFactor,
            anchor: Anchor.center);

  double hitBoxFactor;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox(
      isSolid: true,
      collisionType: CollisionType.passive,
      radius: radius * hitBoxFactor,
      position: Vector2.all(radius),
      anchor: Anchor.center,
    ));
    //debugMode = true;
    world.pellets.pelletsRemainingNotifier.value += 1;
  }

  @override
  Future<void> onRemove() async {
    world.pellets.pelletsRemainingNotifier.value -= 1;
    super.onRemove();
  }
}
