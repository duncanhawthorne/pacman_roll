import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../endless_runner.dart';
import '../endless_world.dart';
import '../effects/jump_effect.dart';
import '../helper.dart';
import 'point.dart';
import 'powerpoint.dart';
import 'ball.dart';
import 'dart:math';
import 'dart:core';

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
  //Ball? underlyingBallLegacy;
  //bool maniacMode = false;
  Ball underlyingBallReal = Ball();
  //bool online = true;
  int ghostScaredTime = 0;
  int ghostNumber = 1;
  //bool ghostScared = false;
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

  Ball createUnderlyingBall() {
    Ball underlyingBallRealTmp = Ball();
    //underlyingBallReal.ghostBall =
    //    isGhost; //FIXME should do this in the initiator, but didn't work
    underlyingBallRealTmp.realCharacter =
        this; //FIXME should do this in the initiator, but didn't work
    //underlyingBallLegacy = underlyingBallReal;
    if (isGhost) {
      underlyingBallRealTmp.bodyDef!.position =
          Vector2(0, -12); //FIXME -12 hardcoded
    }
    return underlyingBallRealTmp;
  }

  @override
  Future<void> onLoad() async {
    underlyingBallReal = createUnderlyingBall();
    world.add(underlyingBallReal);

    // This defines the different animation states that the player can be in.
    animations = isGhost
        ? {
            PlayerState.running: SpriteAnimation.spriteList(
              [await game.loadSprite('dash/ghost1.png')],
              stepTime: double.infinity,
            ),
            PlayerState.scared: SpriteAnimation.spriteList(
              [
                await game.loadSprite('dash/ghostscared1.png'),
                await game.loadSprite('dash/ghostscared2.png')
              ],
              stepTime: 0.1,
            ),
            PlayerState.eating: SpriteAnimation.spriteList(
              [await game.loadSprite('dash/dash_falling.png')],
              stepTime: double.infinity,
            ),
          }
        : {
            PlayerState.running: SpriteAnimation.spriteList(
              [await game.loadSprite('dash/pacmanman.png')],
              stepTime: double.infinity,
            ),
            PlayerState.scared: SpriteAnimation.spriteList(
              [await game.loadSprite('dash/pacmanman_angry.png')],
              stepTime: double.infinity,
            ),
            PlayerState.eating: SpriteAnimation.spriteList(
              [
                await game.loadSprite('dash/pacmanman_eat.png'),
                await game.loadSprite('dash/pacmanman.png')
              ], //FIXME
              stepTime: 0.25,
            ),
          };
    // The starting state will be that the player is running.
    current = PlayerState.running;
    _lastPosition.setFrom(position);

    if (realsurf) {
      accelerometerEventStream().listen(
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

  void handleCollisionWithPlayer(Player otherPlayer) {
    if (!isGhost && otherPlayer.isGhost) {
      if (otherPlayer.current == PlayerState.scared) {
        //pacman eats ghost
        globalAudioController!.playSfx(SfxType.hit);
        removeEnemy(otherPlayer);
        addGhost(world);
      } else {
        //ghost kills pacman
        globalAudioController!.playSfx(SfxType.damage);
        underlyingBallReal.removeFromParent();
        underlyingBallReal = createUnderlyingBall();
        world.add(underlyingBallReal);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isGhost && current == PlayerState.scared) {
      if (DateTime.now().millisecondsSinceEpoch - ghostScaredTime > 10 * 1000) {
        current = PlayerState.running;
      }
    }

    try {
      position = underlyingBallReal.position;
    } catch (e) {
      p(e); //FIXME
    }


    angle +=
        (position - _lastPosition).length / (size.x / 2) * getMagicParity();

    if (realsurf) {
      force = (target - position) * 0.5 +
          Vector2(0, -world.size.y / 4 / dzoom) -
          velocity * 3 +
          gyroforce * 50;
      velocity += force * dt;
      position += velocity;
    }
    _lastPosition.setFrom(position);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    //FIXME include logic to deal with Player collision here too, so handle the collision twice, once in physics and once in flame, belt and braces
    super.onCollisionStart(intersectionPoints, other);
    if (!isGhost) {
      //only pacman
      if (other is MiniPellet) {
        game.audioController.playSfx(SfxType.waka);
        current = PlayerState.eating;
        Future.delayed(Duration(seconds: 1), () {
          //FIXME deal with repeats
          current = PlayerState.running;
        });
        other.removeFromParent();
      } else if (other is SuperPellet) {
        game.audioController.playSfx(SfxType.ghostsScared);
        current = PlayerState.eating;
        Future.delayed(Duration(seconds: 1), () {
          //FIXME deal with repeats
          current = PlayerState.running;
        });
        for (int i = 0; i < ghostPlayersList.length; i++) {
          ghostPlayersList[i].current = PlayerState.scared;
          ghostPlayersList[i].ghostScaredTime =
              DateTime.now().millisecondsSinceEpoch;
        }
        other.removeFromParent();
      } else if (other is Player) {
        handleCollisionWithPlayer(other);
      }
    }
  }

  /// [towards] should be a normalized vector that points in the direction that
  /// the player should jump.
  void jump(Vector2 towards) {
    current = PlayerState.scared;
    // Since `towards` is normalized we need to scale (multiply) that vector by
    // the length that we want the jump to have.
    final jumpEffect = JumpEffect(towards..scaleTo(_jumpLength));

    // We only allow jumps when the player isn't already in the air.
    if (!inAir) {
      game.audioController.playSfx(SfxType.ghostsScared);
      add(jumpEffect);
    }
  }
}

enum PlayerState {
  running,
  scared,
  eating,
}
