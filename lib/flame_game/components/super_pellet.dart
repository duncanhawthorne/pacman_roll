import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../pacman_world.dart';
import 'maze.dart';

class SuperPelletCircle extends CircleComponent
    with HasWorldReference<PacmanWorld> {
  SuperPelletCircle({required super.position})
      : super(
            radius: maze.spriteWidth() / 2 * maze.pelletScaleFactor,
            anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox(
      isSolid: true,
      collisionType: CollisionType.passive,
      radius: 0,
      position: Vector2.all(maze.spriteWidth() / 2 * maze.pelletScaleFactor),
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

/// The [Point] components are the components that the [Player] should collect
/// to finish a level. The points are represented by Flame's mascot; Ember.
class SuperPelletSprite extends SpriteAnimationComponent
    with HasGameReference, HasWorldReference<PacmanWorld> {
  SuperPelletSprite() : super(size: spriteSize, anchor: Anchor.center);

  static final Vector2 spriteSize =
      Vector2.all(maze.blockWidth() * maze.pelletScaleFactor);
  final speed = 0;
  Vector2 absPosition = Vector2(0, 0);

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.spriteList(
      [await game.loadSprite('dash/superpellet.png')],
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
