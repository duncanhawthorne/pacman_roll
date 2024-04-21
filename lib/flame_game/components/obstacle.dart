import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../endless_world.dart';
import '../constants.dart';

/// The [Obstacle] component can represent three different types of obstacles
/// that the player can run into.
class Obstacle extends SpriteAnimationComponent with HasGameReference, HasWorldReference<EndlessWorld> {
  Obstacle.small({super.position})
      : _srcSize = Vector2.all(16),
        _srcPosition = Vector2.all(32),
        super(
          size: Vector2.all(100 / dzoom),
          anchor: Anchor.bottomLeft,
        );

  Obstacle.tall({super.position})
      : _srcSize = Vector2(32, 48),
        _srcPosition = Vector2.zero(),
        super(
          size: Vector2(200, 250),
          anchor: Anchor.bottomLeft,
        );

  Obstacle.wide({super.position})
      : _srcSize = Vector2(32, 16),
        _srcPosition = Vector2(48, 32),
        super(
          size: Vector2(200, 100),
          anchor: Anchor.bottomLeft,
        );

  /// Generates a random obstacle of type [ObstacleType].
  factory Obstacle.random({
    Vector2? position,
    Random? random,
    bool canSpawnTall = true,
  }) {
    //final values = canSpawnTall
    //    ? const [ObstacleType.small, ObstacleType.tall, ObstacleType.wide]
    //    : const [ObstacleType.small, ObstacleType.wide];
    const obstacleType = ObstacleType.small;
    switch (obstacleType) {
      case ObstacleType.small:
        return Obstacle.small(position: position);
      case ObstacleType.tall:
        return Obstacle.tall(position: position);
      case ObstacleType.wide:
        return Obstacle.wide(position: position);
    }
  }

  // ignore: unused_field
  final Vector2 _srcSize;
  // ignore: unused_field
  final Vector2 _srcPosition;

  @override
  Future<void> onLoad() async {
    animation = await game.loadSpriteAnimation(
      'dhember.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: Vector2.all(16),
        stepTime: 0.15,
      ),
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
    // have set for the world.
    // `dt` here stands for delta time and it is the time, in seconds, since the
    // last update ran. We need to multiply the speed by `dt` to make sure that
    // the speed of the obstacles are the same no matter the refresh rate/speed
    // of your device.
    //position.x -= world.speed * dt;
    position.y -= world.speed * dt;

    // When the component is no longer visible on the screen anymore, we
    // remove it.
    // The position is defined from the upper left corner of the component (the
    // anchor) and the center of the world is in (0, 0), so when the components
    // position plus its size in X-axis is outside of minus half the world size
    // we know that it is no longer visible and it can be removed.
    if (position.y + size.y < -world.size.y / dzoom / 2) {
      removeFromParent();
    }
  }
}

enum ObstacleType {
  small,
  tall,
  wide,
}
