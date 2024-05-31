import '../pacman_world.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../constants.dart';
import '../helper.dart';
import 'dart:math';

class SuperPelletCircle extends CircleComponent
    with HasWorldReference<PacmanWorld> {
  SuperPelletCircle({required super.position})
      : super(
            radius:
                blockWidth() * miniPelletAndSuperPelletScaleFactor / 2,
            anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    CircleHitbox x = CircleHitbox(
      isSolid: true,
      collisionType: CollisionType.passive,
      position: Vector2.all(
          blockWidth() * miniPelletAndSuperPelletScaleFactor / 2),
      radius: blockWidth() * miniPelletAndSuperPelletScaleFactor / 2,
      anchor: Anchor.center,
    );
    add(x);
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
      Vector2.all(blockWidth() * miniPelletAndSuperPelletScaleFactor);
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
