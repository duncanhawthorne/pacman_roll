import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

import '../../audio/sounds.dart';
import '../endless_runner.dart';
import '../constants.dart';
import '../endless_world.dart';
import '../effects/hurt_effect.dart';
import 'obstacle.dart';
import 'point.dart';

/// The [Player] is the component that the physical player of the game is
/// controlling.
class Boat extends SpriteAnimationGroupComponent<BoatState>
    with
        CollisionCallbacks,
        HasWorldReference<EndlessWorld>,
        HasGameReference<EndlessRunner> {
  Boat({
    required this.addScore,
    required this.resetScore,
    super.position,
  }) : super(size: Vector2.all(150 / dzoom), anchor: Anchor.center, priority: 1);

  final void Function({int amount}) addScore;
  final VoidCallback resetScore;

  // The current velocity that the player has that comes from being affected by
  // the gravity. Defined in virtual pixels/s².
  //double _gravityVelocity = 0;

  // The maximum length that the player can jump. Defined in virtual pixels.
  //final double _jumpLength = 600;

  Vector2 pull = Vector2.all(0);
  Vector2 target = Vector2(200,700);
  Vector2 velocity = Vector2.all(0);
  Vector2 force = Vector2.all(0);

  // Whether the player is currently in the air, this can be used to restrict
  // movement for example.
  bool get inAir => (position.y + size.y / 2) < world.groundLevel;

  // Used to store the last position of the player, so that we later can
  // determine which direction that the player is moving.
  final Vector2 _lastPosition = Vector2.zero();

  // When the player has velocity pointing downwards it is counted as falling,
  // this is used to set the correct animation for the player.
  bool get isFalling => _lastPosition.y < position.y;

  @override
  Future<void> onLoad() async {
    // This defines the different animation states that the player can be in.
    animations = {
      BoatState.running: await game.loadSpriteAnimation(
        'dash/dash_running.png',
        SpriteAnimationData.sequenced(
          amount: 4,
          textureSize: Vector2.all(16),
          stepTime: 0.15,
        ),
      ),
      BoatState.jumping: SpriteAnimation.spriteList(
        [await game.loadSprite('dash/dash_jumping.png')],
        stepTime: double.infinity,
      ),
      BoatState.falling: SpriteAnimation.spriteList(
        [await game.loadSprite('dash/dash_falling.png')],
        stepTime: double.infinity,
      ),
    };
    // The starting state will be that the player is running.
    current = BoatState.running;
    _lastPosition.setFrom(position);

    // When adding a CircleHitbox without any arguments it automatically
    // fills up the size of the component as much as it can without overflowing
    // it.
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    // When we are in the air the gravity should affect our position and pull
    // us closer to the ground.
    /*
    if (inAir) {
      _gravityVelocity += world.gravity * dt;
      position.y += _gravityVelocity;

      if (isFalling) {
        current = PlayerState.falling;
      }
    }

    final belowGround = position.y + size.y / 2 > world.groundLevel;
    // If the player's new position would overshoot the ground level after
    // updating its position we need to move the player up to the ground level
    // again.
    if (belowGround) {
      position.y = world.groundLevel - size.y / 2;
      _gravityVelocity = 0;
      current = PlayerState.running;
    }

     */
    //position += pull * 1;
    force = Vector2.all(0.0);//(target - position) * 0.5 + Vector2(-640,0) - velocity*3;
    velocity += force * dt;
    position += velocity;
    _lastPosition.setFrom(position);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints,
      PositionComponent other,
      ) {
    super.onCollisionStart(intersectionPoints, other);
    //print("BOat collision");
    // When the player collides with an obstacle it should lose all its points.
    if (other is Obstacle) {
      game.audioController.playSfx(SfxType.damage);
      resetScore();
      add(HurtEffect());
    } else if (other is Point) {
      // When the player collides with a point it should gain a point and remove
      // the `Point` from the game.
      //game.audioController.playSfx(SfxType.score);
      //other.removeFromParent();
      //addScore();
    }
  }

}

enum BoatState {
  running,
  jumping,
  falling,
}
