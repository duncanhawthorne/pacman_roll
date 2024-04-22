import '../endless_world.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../constants.dart';

/// The [MiniPellet] components are the components that the [Player] should collect
/// to finish a level. The points are represented by Flame's mascot; Ember.
class MiniPellet extends SpriteAnimationComponent
    with HasGameReference, HasWorldReference<EndlessWorld> {
  MiniPellet() : super(size: spriteSize, anchor: Anchor.center);

  static final Vector2 spriteSize = Vector2.all(100 / 3 / dzoom);
  final speed = 0;

  @override
  Future<void> onLoad() async {
    /*
    animation = await game.loadSpriteAnimation(
      'ember.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: Vector2.all(16),
        stepTime: 0.15,
      ),
    );

     */

    animation = SpriteAnimation.spriteList(
      [await game.loadSprite('dash/pellet.png')],
      stepTime: double.infinity,
    );

    // Since the original Ember sprite is looking to the right we have to flip
    // it, so that it is facing the player instead.
    flipHorizontallyAroundCenter();

    // When adding a CircleHitbox without any arguments it automatically
    // fills up the size of the component as much as it can without overflowing
    // it.
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    // We need to move the component to the left together with the speed that we
    // have set for the world plus the speed set for the point, so that it
    // is visually moving to the left in the world.
    // `dt` here stands for delta time and it is the time, in seconds, since the
    // last update ran. We need to multiply the speed by `dt` to make sure that
    // the speed of the obstacles are the same no matter the refresh rate/speed
    // of your device.

    //position.y -= (world.speed + speed) * dt;

    // When the component is no longer visible on the screen anymore, we
    // remove it.
    // The position is defined from the upper left corner of the component (the
    // anchor) and the center of the world is in (0, 0), so when the components
    // position plus its size in X-axis is outside of minus half the world size
    // we know that it is no longer visible and it can be removed.
    if (position.y + size.y / 2 < -world.size.y / dzoom / 2) {
      removeFromParent();
    }
  }
}
