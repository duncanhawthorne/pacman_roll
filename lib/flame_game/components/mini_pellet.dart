import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../pacman_world.dart';
import '../maze.dart';

class MiniPelletCircle extends CircleComponent
    with HasWorldReference<PacmanWorld>, IgnoreEvents {
  MiniPelletCircle({required super.position})
      : super(
            radius: maze.spriteWidth() / 2 * Maze.pelletScaleFactor / 3,
            anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox(
      isSolid: true,
      collisionType: CollisionType.passive,
      radius: 0,
      position:
          Vector2.all(maze.spriteWidth() / 2 * Maze.pelletScaleFactor / 3),
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

/// The [MiniPelletSprite] components are the components that the [Player] should collect
/// to finish a level. The points are represented by Flame's mascot; Ember.
class MiniPelletSprite extends SpriteAnimationComponent
    with HasGameReference, HasWorldReference<PacmanWorld>, IgnoreEvents {
  MiniPelletSprite() : super(size: spriteSize, anchor: Anchor.center);

  static final Vector2 spriteSize =
      Vector2.all(maze.blockWidth() * Maze.pelletScaleFactor);
  final speed = 0;
  Vector2 absPosition = Vector2(0, 0);

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.spriteList(
      [await game.loadSprite('dash/pellet.png')],
      stepTime: double.infinity,
    );
    // When adding a CircleHitbox without any arguments it automatically
    // fills up the size of the component as much as it can without overflowing
    // it.
    add(CircleHitbox(collisionType: CollisionType.passive));
    world.pelletsRemainingNotifier.value += 1;
  }

  @override
  Future<void> onRemove() async {
    world.pelletsRemainingNotifier.value -= 1;
    super.onRemove();
  }
}
