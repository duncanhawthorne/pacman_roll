
import 'package:endless_runner/flame_game/helper.dart';

import '../endless_world.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../constants.dart';

/// The [MiniPellet] components are the components that the [Player] should collect
/// to finish a level. The points are represented by Flame's mascot; Ember.
class MiniPellet extends SpriteAnimationComponent
    with HasGameReference, HasWorldReference<EndlessWorld> {
  MiniPellet() : super(size: spriteSize, anchor: Anchor.center);

  static final Vector2 spriteSize = Vector2.all(getSingleSquareWidth() * miniPelletAndSuperPelletScaleFactor);
  final speed = 0;
  Vector2 absPosition = Vector2(0,0);

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.spriteList(
      [await game.loadSprite('dash/pellet.png')],
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
    if (actuallyRotateSprites) {
      position = world.screenPos(absPosition);
    }
  }
}
