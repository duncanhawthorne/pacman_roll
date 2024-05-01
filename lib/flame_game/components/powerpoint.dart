import '../endless_world.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../constants.dart';
import '../helper.dart';

/// The [Point] components are the components that the [Player] should collect
/// to finish a level. The points are represented by Flame's mascot; Ember.
class SuperPellet extends SpriteAnimationComponent
    with HasGameReference, HasWorldReference<EndlessWorld> {
  SuperPellet() : super(size: spriteSize, anchor: Anchor.center);

  static final Vector2 spriteSize = Vector2.all(100 / 3 / flameGameZoom);
  final speed = 0;
  Vector2 absPosition = Vector2(0,0);

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.spriteList(
      [await game.loadSprite('dash/superpellet.png')],
      stepTime: double.infinity,
    );
    // When adding a CircleHitbox without any arguments it automatically
    // fills up the size of the component as much as it can without overflowing
    // it.
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position = screenPos(world.worldAngle, absPosition);
  }
}
