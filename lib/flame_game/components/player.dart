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
import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:core';
import 'package:flutter/material.dart';
//import 'package:sky_engine/ui/painting.dart'
//as dh_image;

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
            size: Vector2.all(getSingleSquareWidth()),
            anchor: Anchor.center,
            priority: 1);

  final bool isGhost;
  Vector2 startPosition;
  Vector2 vel = Vector2(0, 0);
  Ball underlyingBallReal = Ball(); //to avoid null safety issues
  int ghostNumber = 1;
  int ghostScaredTimeLatest = 0; //a long time ago
  int ghostDeadTimeLatest = 0; //a long time ago
  int pacmanDeadTimeLatest = 0; //a long time ago
  int playerEatingTimeLatest = 0; //a long time ago
  int playerEatingSoundTimeLatest = 0; //a long time ago
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

  void endOfGameTestAndAct() {
    if (world.pelletsRemaining == 0) {
      for (int i = 0; i < ghostPlayersList.length; i++) {
        ghostPlayersList[i]
            .moveUnderlyingBallToVector(kCageLocation + Vector2.random() / 100);
      }
      Future.delayed(
          const Duration(milliseconds: kPacmanHalfEatingResetTimeMillis * 2),
          () {
        game.audioController.playSfx(SfxType.clearedBoard);
      });
    }
  }

  void handleTwoCharactersMeet(PositionComponent other) {
    if (!isGhost) {
      //only pacman
      if (other is MiniPellet) {
        if (playerEatingSoundTimeLatest <
            DateTime.now().millisecondsSinceEpoch -
                kPacmanHalfEatingResetTimeMillis * 2) {
          playerEatingSoundTimeLatest = DateTime.now().millisecondsSinceEpoch;
          game.audioController.playSfx(SfxType.wa);

          Future.delayed(
              const Duration(milliseconds: kPacmanHalfEatingResetTimeMillis),
              () {
            game.audioController.playSfx(SfxType.ka);
          });
        }

        current = PlayerState.eating;
        playerEatingTimeLatest = DateTime.now().millisecondsSinceEpoch;

        other.removeFromParent();
        world.pelletsRemaining -= 1;
        endOfGameTestAndAct();
      } else if (other is SuperPellet) {
        for (int i = 0; i < kGhostChaseTimeMillis / 500; i++) {
          //FIXME just do as loop
          Future.delayed(Duration(milliseconds: 500 * i), () {
            game.audioController.playSfx(SfxType.ghostsScared);
          });
        }

        current = PlayerState.eating;
        playerEatingTimeLatest = DateTime.now().millisecondsSinceEpoch;
        for (int i = 0; i < ghostPlayersList.length; i++) {
          ghostPlayersList[i].current = PlayerState.scared;
          ghostPlayersList[i].ghostScaredTimeLatest =
              DateTime.now().millisecondsSinceEpoch;
        }
        other.removeFromParent();
        world.pelletsRemaining -= 1;
        endOfGameTestAndAct();
      } else if (other is RealCharacter) {
        //belts and braces. Already handled by physics collisions in Ball
        handlePacmanMeetsGhost(other);
      }
    }
  }

  void handlePacmanMeetsGhost(RealCharacter otherPlayer) {
    // ignore: unnecessary_this
    if (!this.isGhost && otherPlayer.isGhost) {
      if (otherPlayer.current == PlayerState.deadGhost) {
        //nothing, but need to keep if condition
      }
      if (otherPlayer.current == PlayerState.scared) {
        //pacman eats ghost

        //pacman visuals
        globalAudioController!.playSfx(SfxType.eatGhost);

        current = PlayerState.eating;
        playerEatingTimeLatest = DateTime.now().millisecondsSinceEpoch;

        //ghost impact
        otherPlayer.current = PlayerState.deadGhost;
        otherPlayer.ghostDeadTimeLatest = DateTime.now().millisecondsSinceEpoch;
        otherPlayer.ghostDeadPosition = Vector2(position.x, position.y);

        //immediately move into cage where out of the way an no ball interactions
        //FIXME somehow ghost can still kill pacman while in this state
        otherPlayer
            .moveUnderlyingBallToVector(kCageLocation + Vector2.random() / 100);

        Future.delayed(const Duration(milliseconds: kGhostResetTimeMillis - 5),
            () {
          //delay so doesn't have time to move by gravity after being placed in the right position
          otherPlayer.moveUnderlyingBallToVector(
              kGhostStartLocation + Vector2.random() / 100);
        });
      } else {
        //ghost kills pacman
        if (globalPhysicsLinked) {
          //prevent multiple hits

          globalAudioController!.playSfx(SfxType.pacmanDeath);
          pacmanDeadTimeLatest = DateTime.now().millisecondsSinceEpoch;
          current = PlayerState.deadPacman;

          globalPhysicsLinked = false;

          Future.delayed(
              const Duration(milliseconds: kPacmanDeadResetTimeMillis), () {
            if (!globalPhysicsLinked) {
              //prevent multiple resets

              world.addScore(); //score counting deaths
              moveUnderlyingBallToVector(kPacmanStartLocation);
              for (var i = 0; i < ghostPlayersList.length; i++) {
                ghostPlayersList[i].moveUnderlyingBallToVector(
                    kGhostStartLocation + Vector2.random() / 100);
                ghostPlayersList[i].ghostDeadTimeLatest = 0;
                ghostPlayersList[i].ghostScaredTimeLatest = 0;
              }
              globalPhysicsLinked = true;
            }
          });
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
              [
                Sprite(createPacmanStandard())
              ], //game.loadSprite('dash/pacmanman.png')],
              stepTime: double.infinity,
            ),
            PlayerState.eating: SpriteAnimation.spriteList(
              [
                Sprite(createPacmanStandard()),
                Sprite(createPacmanMouthClosed())
              ], //game.loadSprite('dash/pacmanman.png')],
              stepTime: kPacmanHalfEatingResetTimeMillis / 1000,
            )
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

    //FIXME instead of testing this every frame, move into futures, and still test every frame, but only when in the general zone that need to test this
    if (isGhost && current == PlayerState.scared) {
      if (DateTime.now().millisecondsSinceEpoch - ghostScaredTimeLatest >
          kGhostChaseTimeMillis) {
        current = PlayerState.normal;
      }
    }
    if (isGhost && current == PlayerState.deadGhost) {
      if (DateTime.now().millisecondsSinceEpoch - ghostDeadTimeLatest >
          kGhostResetTimeMillis) {
        current = PlayerState.normal;
      }
    }
    if (!isGhost && current == PlayerState.eating) {
      if (DateTime.now().millisecondsSinceEpoch - playerEatingTimeLatest >
          2 * kPacmanHalfEatingResetTimeMillis) {
        current = PlayerState.normal;
      }
    }
    if (!isGhost && current == PlayerState.deadPacman) {
      if (DateTime.now().millisecondsSinceEpoch - playerEatingTimeLatest >
          kPacmanDeadResetTimeMillis) {
        current = PlayerState.normal;
      }
    }

    if (globalPhysicsLinked) {
      try {
        vel = Vector2(underlyingBallReal.body.linearVelocity.x,
            underlyingBallReal.body.linearVelocity.y);
      } catch (e) {
        p(e);
      }
      if (isGhost && current == PlayerState.deadGhost) {
        double timefrac =
            (DateTime.now().millisecondsSinceEpoch - ghostDeadTimeLatest) /
                (kGhostResetTimeMillis);
        position = ghostDeadPosition * (1 - timefrac) +
            kGhostStartLocation * (timefrac);
      } else {
        try {
          position = underlyingBallReal.position;
        } catch (e) {
          //effectively leave unchanged and pick up next frame
          p(e); //FIXME if physical ball not initialised properly
        }

        if (!debugMode) {
          if (position.x > 9 * ksingleSquareWidthProxy) {
            //Vector2 vel = (position - _lastPosition)/dt *100;

            moveUnderlyingBallToVector(kLeftPortalLocation);
            Future.delayed(const Duration(seconds: 0), () {
              //FIXME physical ball not initialised immediately
              underlyingBallReal.body.linearVelocity = vel;
            });
          } else if (position.x < -9 * ksingleSquareWidthProxy) {
            moveUnderlyingBallToVector(kRightPortalLocation);
            Future.delayed(const Duration(seconds: 0), () {
              //FIXME physical ball not initialised immediately
              underlyingBallReal.body.linearVelocity = vel;
            });
          }
        }

        angle += (position - _lastPosition).length /
            (size.x / 2) *
            getMagicParity(world, this, vel.x, vel.y);
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
    handleTwoCharactersMeet(other);
  }

  final Paint _pacmanYellowPaint = Paint()..color = Colors.yellowAccent;
  final Rect rect = Rect.fromCenter(
      center: Offset(getSingleSquareWidth() / 2, getSingleSquareWidth() / 2),
      width: getSingleSquareWidth(),
      height: getSingleSquareWidth());
  final Rect rect100 = Rect.fromCenter(
      center: const Offset(100 / 2, 100 / 2), width: 100, height: 100);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isGhost && current == PlayerState.deadPacman) {
      double tween = 0;
      if (current == PlayerState.deadPacman &&
          DateTime.now().millisecondsSinceEpoch - pacmanDeadTimeLatest <
              kPacmanDeadResetTimeMillis) {
        tween = (DateTime.now().millisecondsSinceEpoch - pacmanDeadTimeLatest) /
            kPacmanDeadResetTimeMillis;
      }
      double mouthWidth = 5 / 32 * (1 - tween) + 1 * tween;
      canvas.drawArc(rect, 2 * pi * ((mouthWidth / 2) + 0.5),
          2 * pi * (1 - mouthWidth), true, _pacmanYellowPaint);
    }
  }

  //FIXME draw once and then render rather than drawing each frame
  ui.Image createPacmanStandard() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const mouthWidth = 5 / 32;
    canvas.drawArc(rect100, 2 * pi * ((mouthWidth / 2) + 0.5),
        2 * pi * (1 - mouthWidth), true, _pacmanYellowPaint);
    return recorder.endRecording().toImageSync(100, 100);
  }

  ui.Image createPacmanMouthClosed() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const mouthWidth = 0;
    canvas.drawArc(rect100, 2 * pi * ((mouthWidth / 2) + 0.5),
        2 * pi * (1 - mouthWidth), true, _pacmanYellowPaint);
    return recorder.endRecording().toImageSync(100, 100);
  }
}

enum PlayerState { normal, scared, eating, deadGhost, deadPacman }
