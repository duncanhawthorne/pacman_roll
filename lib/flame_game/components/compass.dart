import '../endless_world.dart';
import 'package:flame/components.dart';
import '../constants.dart';
import '../helper.dart';
import 'dart:math';

/// The [MiniPellet] components are the components that the [Player] should collect
/// to finish a level. The points are represented by Flame's mascot; Ember.
class Compass extends SpriteAnimationComponent
    with HasGameReference, HasWorldReference<EndlessWorld> {
  Compass() : super(size: spriteSize, anchor: Anchor.center);

  static final Vector2 spriteSize = Vector2.all(
      singleSquareWidth() * miniPelletAndSuperPelletScaleFactor / 2);
  Vector2 absPosition = kCompassLocation;

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.spriteList(
      [await game.loadSprite('dash/pellet.png')],
      stepTime: double.infinity,
    );
  }

  Vector2 capVector(Vector2 tmp) {
    return Vector2(max(-0.5, min(0.5, tmp.x)), max(-0.5, min(0.5, tmp.y)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position = kCompassLocation +
        capVector(world.gravity / 25) * singleSquareWidth();
  }
}
