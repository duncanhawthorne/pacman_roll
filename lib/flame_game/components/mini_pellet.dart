import '../helper.dart';

import '../pacman_world.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../constants.dart';

class MiniPelletCircle extends CircleComponent
    with HasWorldReference<PacmanWorld> {
  MiniPelletCircle({required super.position})
      : super(
            radius: spriteWidth() / 2 * pelletScaleFactor / 3,
            anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox(isSolid: true, collisionType: CollisionType.passive));
    /*
    CircleHitbox x = CircleHitbox(
        isSolid: true,
        position: Vector2.all(
            blockWidth() * miniPelletAndSuperPelletScaleFactor / 2 / 3),
        anchor: Anchor.center,
        radius:
            blockWidth() * miniPelletAndSuperPelletScaleFactor / 2 / 3,
        collisionType: CollisionType.passive);
    add(x);
    //x.debugMode = true;
     */
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
    with HasGameReference, HasWorldReference<PacmanWorld> {
  MiniPelletSprite() : super(size: spriteSize, anchor: Anchor.center);

  static final Vector2 spriteSize =
      Vector2.all(blockWidth() * pelletScaleFactor);
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
