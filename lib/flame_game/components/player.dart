import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../endless_runner.dart';
import '../endless_world.dart';
import '../constants.dart';
import '../helper.dart';
import 'point.dart';
import 'powerpoint.dart';
import 'ball.dart';
import 'dart:math';
import 'dart:core';

/// The [RealCharacter] is the component that the physical player of the game is
/// controlling.
class RealCharacter extends SpriteAnimationGroupComponent<PlayerState>
    with
        CollisionCallbacks,
        HasWorldReference<EndlessWorld>,
        HasGameReference<EndlessRunner> {
  RealCharacter({
    required this.isGhost,
    required this.startPosition,
    super.position,
  }) : super(
            size: Vector2.all(min(ksizex, ksizey) / dzoom / mazelen),
            anchor: Anchor.center,
            priority: 1);

  final bool isGhost;
  Vector2 startPosition;
  Ball underlyingBallReal = Ball(); //to avoid null safety issues
  bool physicsLinked = true;
  int ghostScaredTime = 0; //a long time ago
  int ghostNumber = 1; //FIXME make this do something
  int ghostDeadTime = 0; //a long time ago
  Vector2 ghostDeadPosition = Vector2(0, 0);

  // Used to store the last position of the player, so that we later can
  // determine which direction that the player is moving.
  final Vector2 _lastPosition = Vector2.zero();

  Ball createUnderlyingBall(Vector2 startPosition) {
    Ball underlyingBallRealTmp = Ball();
    underlyingBallRealTmp.realCharacter =
        this; //FIXME should do this in the initiator, but didn't work
    underlyingBallRealTmp.bodyDef!.position = startPosition;
    return underlyingBallRealTmp;
  }

  void moveUnderlyingBallToVector(Vector2 targetLoc) {
    underlyingBallReal.removeFromParent();
    underlyingBallReal = createUnderlyingBall(targetLoc);
    world.add(underlyingBallReal);
  }

  void handleCollisionWithPlayer(RealCharacter otherPlayer) {
    if (!isGhost && otherPlayer.isGhost) {
      if (otherPlayer.current == PlayerState.scared ||
          otherPlayer.current == PlayerState.deadGhost) {
        if (otherPlayer.physicsLinked) {
          //pacman eats ghost
          globalAudioController!.playSfx(SfxType.hit);
          otherPlayer.moveUnderlyingBallToVector(kGhostStartLocation);
          otherPlayer.physicsLinked = false;
          otherPlayer.current = PlayerState.deadGhost;
          otherPlayer.ghostDeadTime = DateTime.now().millisecondsSinceEpoch;
          otherPlayer.ghostDeadPosition = Vector2(position.x, position.y);
          Future.delayed(const Duration(seconds: ghostResetTime), () {
            int tmpGhostNumber = otherPlayer.ghostNumber;
            otherPlayer.physicsLinked = true;
            removeGhost(
                otherPlayer); // FIXME ideally just move ball rather than removing and re-adding
            addGhost(world, tmpGhostNumber);
          });
        }
      } else {
        //ghost kills pacman
        if (globalPhysicsLinked) {
          //prevent multiple hits
          globalAudioController!.playSfx(SfxType.damage);
          world.addScore();
          globalPhysicsLinked = false;

          Future.delayed(const Duration(seconds: ghostResetTime), () {
            if (!globalPhysicsLinked) {
              //prevent multiple resets
              moveUnderlyingBallToVector(kPacmanStartLocation);
              for (var i = 0; i < ghostPlayersList.length; i++) {
                ghostPlayersList[i].moveUnderlyingBallToVector(
                    kGhostStartLocation + Vector2.random() / 100);
                ghostPlayersList[i].ghostDeadTime = 0;
                ghostPlayersList[i].ghostScaredTime = 0;
              }
              globalPhysicsLinked = true;
            }
          });
          /*
        underlyingBallReal.removeFromParent();
        underlyingBallReal = createUnderlyingBall();
        world.add(underlyingBallReal);

         */
        }
      }
    }
  }

  @override
  Future<void> onLoad() async {
    underlyingBallReal = createUnderlyingBall(startPosition);
    world.add(underlyingBallReal);

    // This defines the different animation states that the player can be in.
    animations = isGhost
        ? {
            PlayerState.running: SpriteAnimation.spriteList(
              [
                await game.loadSprite(ghostNumber == 1
                    ? 'dash/ghost1.png'
                    : ghostNumber == 2
                        ? 'dash/ghost2.png'
                        : 'dash/ghost3.png')
              ],
              stepTime: double.infinity,
            ),
            PlayerState.scared: SpriteAnimation.spriteList(
              [
                await game.loadSprite('dash/ghostscared1.png'),
                await game.loadSprite('dash/ghostscared2.png')
              ],
              stepTime: 0.1,
            ),
            PlayerState.deadGhost: SpriteAnimation.spriteList(
              [await game.loadSprite('dash/eyes.png')],
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

    // When adding a CircleHitbox without any arguments it automatically
    // fills up the size of the component as much as it can without overflowing
    // it.
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isGhost && current == PlayerState.scared) {
      if (DateTime.now().millisecondsSinceEpoch - ghostScaredTime > 10 * 1000) {
        current = PlayerState.running;
      }
    }

    if (globalPhysicsLinked) {
      if (physicsLinked) {
        try {
          position = underlyingBallReal.position;
        } catch (e) {
          p(e); //FIXME
        }

        if (!debugMode) {
          if (position.x > 36) {
            moveUnderlyingBallToVector(kLeftPortalLocation);
            //FIXME keep momentum. Should be able to apply linear force
          } else if (position.x < -36) {
            moveUnderlyingBallToVector(kRightPortalLocation);
            //FIXME keep momentum. Should be able to apply linear force
          }
        }

        angle +=
            (position - _lastPosition).length / (size.x / 2) * getMagicParity();
      } else {
        assert(isGhost);
        double timefrac =
            (DateTime.now().millisecondsSinceEpoch - ghostDeadTime) /
                (1000 * ghostResetTime);
        position = ghostDeadPosition * (1 - timefrac) +
            kGhostStartLocation * (timefrac);
      }
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
        Future.delayed(const Duration(seconds: 1), () {
          //FIXME deal with repeats
          current = PlayerState.running;
        });
        other.removeFromParent();
      } else if (other is SuperPellet) {
        game.audioController.playSfx(SfxType.ghostsScared);
        current = PlayerState.eating;
        Future.delayed(const Duration(seconds: 1), () {
          //FIXME deal with repeats
          current = PlayerState.running;
        });
        for (int i = 0; i < ghostPlayersList.length; i++) {
          ghostPlayersList[i].current = PlayerState.scared;
          ghostPlayersList[i].ghostScaredTime =
              DateTime.now().millisecondsSinceEpoch;
        }
        other.removeFromParent();
      } else if (other is RealCharacter) {
        handleCollisionWithPlayer(other);
      }
    }
  }
}

enum PlayerState { running, scared, eating, deadGhost }
