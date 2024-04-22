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
  bool localObjectPhysicsLinked = true;
  int ghostScaredTime = 0; //a long time ago
  int ghostNumber = 1; //FIXME make this do something
  int ghostDeadTime = 0; //a long time ago
  int playerEatingTime = 0; //a long time ago
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

  void handlePacmanMeetsGhost(RealCharacter otherPlayer) {
    // ignore: unnecessary_this
    if (!this.isGhost && otherPlayer.isGhost) {
      if (otherPlayer.current == PlayerState.scared ||
          otherPlayer.current == PlayerState.deadGhost) {
        if (otherPlayer.localObjectPhysicsLinked) {
          //pacman eats ghost

          //pacman visuals
          globalAudioController!.playSfx(SfxType.hit);
          current = PlayerState.eating;
          playerEatingTime = DateTime.now().millisecondsSinceEpoch;

          //ghost impact
          otherPlayer.moveUnderlyingBallToVector(kGhostStartLocation + Vector2.random() / 100); //FIXME check doesn't cause inconsistency with animation which goes to one exact place
          otherPlayer.localObjectPhysicsLinked = false; //FIXME think can just use deadGhost state instead
          otherPlayer.current = PlayerState.deadGhost;
          otherPlayer.ghostDeadTime = DateTime.now().millisecondsSinceEpoch;
          otherPlayer.ghostDeadPosition = Vector2(position.x, position.y);
          Future.delayed(const Duration(seconds: ghostResetTime), () {
            int tmpGhostNumber = otherPlayer.ghostNumber;
            otherPlayer.localObjectPhysicsLinked = true;
            otherPlayer.current = PlayerState.normal;
            //removeGhost(
            //    otherPlayer); // FIXME ideally just move ball rather than removing and re-adding
            //addGhost(world, tmpGhostNumber);
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
            PlayerState.normal: SpriteAnimation.spriteList(
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
            PlayerState.normal: SpriteAnimation.spriteList(
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
    current = PlayerState.normal;
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
        current = PlayerState.normal;
      }
    }
    if (!isGhost && current == PlayerState.eating) {
      if (DateTime.now().millisecondsSinceEpoch - playerEatingTime > 1 * 1000) {
        current = PlayerState.normal;
      }
    }

    if (globalPhysicsLinked) {
      if (localObjectPhysicsLinked) {
        try {
          position = underlyingBallReal.position;
        } catch (e) {
          p(e); //FIXME if physical ball not initialised properly
        }

        if (!debugMode) {
          if (position.x > 36) {
            moveUnderlyingBallToVector(kLeftPortalLocation);
            //FIXME keep momentum. Should be able to apply linear impulse
          } else if (position.x < -36) {
            moveUnderlyingBallToVector(kRightPortalLocation);
            //FIXME keep momentum. Should be able to apply linear impulse
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
    super.onCollisionStart(intersectionPoints, other);
    if (!isGhost) {
      //only pacman
      if (other is MiniPellet) {
        game.audioController.playSfx(SfxType.waka);
        current = PlayerState.eating;
        playerEatingTime = DateTime.now().millisecondsSinceEpoch;
        other.removeFromParent();
      } else if (other is SuperPellet) {
        game.audioController.playSfx(SfxType.ghostsScared); //FIXME extend and don't cut out
        current = PlayerState.eating;
        playerEatingTime = DateTime.now().millisecondsSinceEpoch;
        for (int i = 0; i < ghostPlayersList.length; i++) {
          ghostPlayersList[i].current = PlayerState.scared;
          ghostPlayersList[i].ghostScaredTime =
              DateTime.now().millisecondsSinceEpoch;
        }
        other.removeFromParent();
      } else if (other is RealCharacter) {
        //belts and braces. Already handled by physics collisions in Ball
        handlePacmanMeetsGhost(other);
      }
    }
  }
}

enum PlayerState { normal, scared, eating, deadGhost }
