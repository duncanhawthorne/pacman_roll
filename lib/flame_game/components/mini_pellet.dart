import '../helper.dart';

import '../endless_world.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../constants.dart';

class MiniPelletCircle extends CircleComponent {
  MiniPelletCircle({required super.position})
      : super(
            radius: getSingleSquareWidth() *
                miniPelletAndSuperPelletScaleFactor /
                2 *
                1 /
                3,
            anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox(
        isSolid: true,
        radius:
            getSingleSquareWidth() * miniPelletAndSuperPelletScaleFactor / 2,
        collisionType: CollisionType.passive));
  }
}

/// The [MiniPellet] components are the components that the [Player] should collect
/// to finish a level. The points are represented by Flame's mascot; Ember.
class MiniPellet extends SpriteAnimationComponent
    with HasGameReference, HasWorldReference<EndlessWorld> {
  MiniPellet() : super(size: spriteSize, anchor: Anchor.center);

  static final Vector2 spriteSize =
      Vector2.all(getSingleSquareWidth() * miniPelletAndSuperPelletScaleFactor);
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
  }
}
