import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../endless_runner.dart';
import '../endless_world.dart';
import '../effects/hurt_effect.dart';
import '../effects/jump_effect.dart';
import 'obstacle.dart';
import 'point.dart';
import 'powerpoint.dart';
import 'ball.dart';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';
import '../constants.dart';

/// The [Player] is the component that the physical player of the game is
/// controlling.
class Player extends SpriteAnimationGroupComponent<PlayerState>
    with
        CollisionCallbacks,
        HasWorldReference<EndlessWorld>,
        HasGameReference<EndlessRunner> {
  Player({
    //required this.addScore,
    //required this.resetScore,
    required this.isGhost,
    super.position,
  }) : super(
            size: Vector2.all(min(ksizex, ksizey) / dzoom / 2 / 14),
            anchor: Anchor.center,
            priority: 1);

  //final void Function({int amount}) addScore;
  //final VoidCallback resetScore;
  final bool isGhost;

  // The current velocity that the player has that comes from being affected by
  // the gravity. Defined in virtual pixels/s².
  //double _gravityVelocity = 0;

  // The maximum length that the player can jump. Defined in virtual pixels.
  final double _jumpLength = 600;

  //Vector2 pull = Vector2.all(0);
  Vector2 target = Vector2(200, 700);
  Vector2 velocity = Vector2.all(0);
  Vector2 force = Vector2.all(0);
  Vector2 gyroforce = Vector2.all(0);
  Ball? underlyingBall;
  bool maniacMode = false;
  Ball? underlyingBallReal;
  //bool isGhost = false;

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
    Ball underlyingBallReal = Ball(enemy: isGhost, realCharacter: this);
    underlyingBall = underlyingBallReal;
    if (isGhost) {
      underlyingBall!.bodyDef!.position = Vector2(0, 0);
    }
    world.add(underlyingBallReal);

    // This defines the different animation states that the player can be in.
    animations = {
      PlayerState.running: SpriteAnimation.spriteList(
        [
          await game.loadSprite(
              isGhost ? 'dash/ghost1.png' : 'dash/pacmanman.png')
        ],
        stepTime: double.infinity,
      ),
      PlayerState.jumping: SpriteAnimation.spriteList(
        [await game.loadSprite('dash/pacmanman_angry.png')],
        stepTime: double.infinity,
      ),
      PlayerState.falling: SpriteAnimation.spriteList(
        [await game.loadSprite('dash/dash_falling.png')],
        stepTime: double.infinity,
      ),
    };
    // The starting state will be that the player is running.
    current = PlayerState.running;
    _lastPosition.setFrom(position);

    if (realsurf) {
      // ignore: deprecated_member_use
      accelerometerEvents.listen(
        (AccelerometerEvent event) {
          if (!android) {
            gyroforce.x = -event.x;
            gyroforce.y = 0; //-event.y;
          } else {
            gyroforce.x = event.y / 10;
            gyroforce.y = 0; //-event.y;
          }
        },
        onError: (error) {
          // Logic to handle error
          // Needed for Android in case sensor is not available
        },
        cancelOnError: true,
      );
    }

    // When adding a CircleHitbox without any arguments it automatically
    // fills up the size of the component as much as it can without overflowing
    // it.
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (underlyingBall != null) {
      position = underlyingBall!.position;
    }

    if (realsurf) {
      force = (target - position) * 0.5 +
          Vector2(0, -world.size.y / 4 / dzoom) -
          velocity * 3 +
          gyroforce * 50;
      velocity += force * dt;
      position += velocity;
      _lastPosition.setFrom(position);
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (!isGhost) {
      // When the player collides with an obstacle it should lose all its points.
      if (other is Obstacle) {
        game.audioController.playSfx(SfxType.damage);
        //resetScore();
        add(HurtEffect());
      } else if (other is Point) {
        // When the player collides with a point it should gain a point and remove
        // the `Point` from the game.
        game.audioController.playSfx(SfxType.score);
        other.removeFromParent();
        //addScore();
      } else if (other is Powerpoint) {
        game.audioController.playSfx(SfxType.score);
        maniacMode = true;
        current = PlayerState.jumping;
        //p("start maniac");
        Future.delayed(const Duration(seconds: 10), () {
          maniacMode = false;
          current = PlayerState.running;
          //p("END MANIAC");
          //setStateGlobal();
        });
        other.removeFromParent();
      }
    }
  }

  /// [towards] should be a normalized vector that points in the direction that
  /// the player should jump.
  void jump(Vector2 towards) {
    current = PlayerState.jumping;
    // Since `towards` is normalized we need to scale (multiply) that vector by
    // the length that we want the jump to have.
    final jumpEffect = JumpEffect(towards..scaleTo(_jumpLength));

    // We only allow jumps when the player isn't already in the air.
    if (!inAir) {
      game.audioController.playSfx(SfxType.jump);
      add(jumpEffect);
    }
  }
}

enum PlayerState {
  running,
  jumping,
  falling,
}
