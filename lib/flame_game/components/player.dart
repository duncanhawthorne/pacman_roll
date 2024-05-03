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
import 'package:flutter/foundation.dart';

/// The [RealCharacter] is the component that the physical player of the game is
/// controlling.
class RealCharacter extends SpriteAnimationGroupComponent<CharacterState>
    with
        CollisionCallbacks,
        HasWorldReference<EndlessWorld>,
        HasGameReference<EndlessRunner> {
  RealCharacter({
    required this.isGhost,
    required this.startingPosition,
    super.position,
  }) : super(
            size: Vector2.all(getSingleSquareWidth()),
            anchor: Anchor.center,
            priority: 1);

  final bool isGhost;
  int ghostNumber = 1;

  final Vector2 startingPosition;
  late Ball underlyingBallReal = Ball(realCharacter: this, initialPosition: startingPosition); //to avoid null safety issues

  int ghostScaredTimeLatest = 0; //a long time ago
  int ghostDeadTimeLatest = 0; //a long time ago
  int pacmanDeadTimeLatest = 0; //a long time ago
  int playerEatingTimeLatest = 0; //a long time ago
  int playerEatingSoundTimeLatest = 0; //a long time ago
  Vector2 ghostDeadPosition = Vector2(0, 0);
  double underlyingAngle = 0;

  // Used to store the last position of the player, so that we later can
  // determine which direction that the player is moving.
  // ignore: prefer_final_fields
  Vector2 _lastUnderlyingPosition = Vector2.zero();
  //double _lastWorldAngle = 0;
  // ignore: prefer_final_fields
  Vector2 _lastUnderlyingVelocity = Vector2.zero();

  Future<Map<CharacterState, SpriteAnimation>?> getAnimations() async {
    return isGhost
        ? {
            CharacterState.normal: SpriteAnimation.spriteList(
              [
                await game.loadSprite(ghostNumber == 1
                    ? 'dash/ghost1.png'
                    : ghostNumber == 2
                        ? 'dash/ghost2.png'
                        : 'dash/ghost3.png')
              ],
              stepTime: double.infinity,
            ),
            CharacterState.scared: SpriteAnimation.spriteList(
              [await game.loadSprite('dash/ghostscared1.png')],
              stepTime: 0.1,
            ),
            CharacterState.scaredIsh: SpriteAnimation.spriteList(
              [
                await game.loadSprite('dash/ghostscared1.png'),
                await game.loadSprite('dash/ghostscared2.png')
              ],
              stepTime: 0.1,
            ),
            CharacterState.deadGhost: SpriteAnimation.spriteList(
              [await game.loadSprite('dash/eyes.png')],
              stepTime: double.infinity,
            ),
          }
        : {
            CharacterState.normal: SpriteAnimation.spriteList(
              [
                kIsWeb
                    ? await game.loadSprite('dash/pacmanman.png')
                    : Sprite(createPacmanStandard())
              ], //game.loadSprite('dash/pacmanman.png')],
              stepTime: double.infinity,
            ),
            CharacterState.eating: SpriteAnimation.spriteList(
              [
                kIsWeb
                    ? await game.loadSprite('dash/pacmanman.png')
                    : Sprite(createPacmanStandard()),
                kIsWeb
                    ? await game.loadSprite('dash/pacmanman_eat.png')
                    : Sprite(createPacmanMouthClosed())
              ], //game.loadSprite('dash/pacmanman.png')],
              stepTime: kPacmanHalfEatingResetTimeMillis / 1000,
            )
          };
  }

  Ball createUnderlyingBall(Vector2 targetPosition) {
    Ball underlyingBallRealTmp = Ball(realCharacter: this, initialPosition: targetPosition);
    //underlyingBallRealTmp.realCharacter =
    //    this;
    //underlyingBallRealTmp.createBody();
    //underlyingBallRealTmp.bodyDef!.position = startPosition;
    return underlyingBallRealTmp;
  }

  Vector2 getUnderlyingBallPosition() {
    try {
      return underlyingBallReal.position;
    } catch (e) {
      //FIXME shouldn't need this
      p(["getUnderlyingBallPosition", e]);
      return _lastUnderlyingPosition; //Vector2(10, 0);
    }
  }

  void setUnderlyingBallPosition(Vector2 targetLoc) {
    underlyingBallReal
        .removeFromParent(); //note possible risk that may try to remove a ball that isn't in the world
    underlyingBallReal = createUnderlyingBall(targetLoc);
    world.add(underlyingBallReal);
  }

  Vector2 getUnderlyingBallVelocity() {
    try {
      return Vector2(underlyingBallReal.body.linearVelocity.x,
          underlyingBallReal.body.linearVelocity.y);
    } catch (e) {
      //FIXME shouldn't need this
      p(["getUnderlyingBallVelocity", e]);
      return _lastUnderlyingVelocity;
    }
  }

  void setUnderlyingVelocity(Vector2 vel) {
    try {
      underlyingBallReal.body.linearVelocity = vel;
    } catch (e) {
      Future.delayed(const Duration(seconds: 0), () {
        //FIXME physical ball not initialised immediately
        underlyingBallReal.body.linearVelocity = vel;
      });
    }
  }

  void endOfGameTestAndAct() {
    if (world.pelletsRemaining == 0) {
      for (int i = 0; i < world.ghostPlayersList.length; i++) {
        world.ghostPlayersList[i]
            .setUnderlyingBallPosition(kCageLocation + Vector2.random() / 100);
      }
      Future.delayed(
          const Duration(milliseconds: kPacmanHalfEatingResetTimeMillis * 2),
          () {
            world.play(SfxType.clearedBoard);
      });
    }
  }

  void handleTwoCharactersMeet(PositionComponent other) {
    if (!isGhost) {
      //only pacman
      if (other is MiniPellet) {
        if (playerEatingSoundTimeLatest <
            world.getNow() -
                kPacmanHalfEatingResetTimeMillis * 2) {
          playerEatingSoundTimeLatest = world.getNow();
          world.play(SfxType.waka);

          /*
          Future.delayed(
              const Duration(milliseconds: kPacmanHalfEatingResetTimeMillis),
              () {
                world.play(SfxType.ka);
          });

           */
        }

        current = CharacterState.eating;
        playerEatingTimeLatest = world.getNow();

        other.removeFromParent();
        world.pelletsRemaining -= 1;
        endOfGameTestAndAct();
      } else if (other is SuperPellet) {
        world.play(SfxType.ghostsScared);
        /*
        for (int i = 0; i < kGhostChaseTimeMillis / 500; i++) { //
          //FIXME just do as loop
          Future.delayed(Duration(milliseconds: 500 * i), () {
            world.play(SfxType.ghostsScared);
          });
        }
         */

        current = CharacterState.eating;
        playerEatingTimeLatest = world.getNow();
        for (int i = 0; i < world.ghostPlayersList.length; i++) {
          world.ghostPlayersList[i].current = CharacterState.scared;
          world.ghostPlayersList[i].ghostScaredTimeLatest =
              world.getNow();
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
      if (otherPlayer.current == CharacterState.deadGhost) {
        //nothing, but need to keep if condition
      }
      if (otherPlayer.current == CharacterState.scared ||
          otherPlayer.current == CharacterState.scaredIsh) {
        //pacman eats ghost

        //pacman visuals
        world.play(SfxType.eatGhost);
        current = CharacterState.eating;
        playerEatingTimeLatest = world.getNow();

        //ghost impact
        otherPlayer.current = CharacterState.deadGhost;
        otherPlayer.ghostDeadTimeLatest = world.getNow();
        otherPlayer.ghostDeadPosition = otherPlayer.getUnderlyingBallPosition();

        //Move ball way offscreen. Stops any physics interactions or collisions
        otherPlayer
            .setUnderlyingBallPosition(kOffScreenLocation + Vector2.random() / 100); //will get moved to right position later by other code in sequence checker
        if (multiplePacmans) {
          world.addPacman(
              world, getUnderlyingBallPosition() + Vector2.random() / 100);
        }

        /*
        Future.delayed(const Duration(milliseconds: kGhostResetTimeMillis - 5),
            () {
          //-5 buffer
          //delay so doesn't have time to move by gravity after being placed in the right position
          otherPlayer.setUnderlyingBallPosition(
              kGhostStartLocation + Vector2.random() / 100);
        });

         */
      } else {
        //ghost kills pacman
        if (globalPhysicsLinked) {
          //prevent multiple hits

          world.play(SfxType.pacmanDeath);
          pacmanDeadTimeLatest = world.getNow();
          current = CharacterState.deadPacman;

          if (world.pacmanPlayersList.length == 1) {
            globalPhysicsLinked = false;
          }
          else {
            //setUnderlyingBallPosition(kPacmanStartLocation);
            assert(multiplePacmans);
            world.removePacman(world, this);
          }

          Future.delayed(
              const Duration(milliseconds: kPacmanDeadResetTimeMillis + 100),
              () {
            //100 buffer
            if (!globalPhysicsLinked) {
              //prevent multiple resets

              world.addScore(); //score counting deaths
              setUnderlyingBallPosition(kPacmanStartLocation);
              for (var i = 0; i < world.ghostPlayersList.length; i++) {
                world.ghostPlayersList[i].setUnderlyingBallPosition(
                    kGhostStartLocation + Vector2.random() / 100);
                world.ghostPlayersList[i].ghostDeadTimeLatest = 0;
                world.ghostPlayersList[i].ghostScaredTimeLatest = 0;
              }
              current = CharacterState.normal;
              globalPhysicsLinked = true;
            }
          });
        }
      }
    }
  }

  @override
  Future<void> onLoad() async {
    setUnderlyingBallPosition(startingPosition); //FIXME shouldn't be necessary, but avoid one frame starting glitch

    animations = await getAnimations();
    current = CharacterState.normal;
    _lastUnderlyingPosition.setFrom(getUnderlyingBallPosition());

    // When adding a CircleHitbox without any arguments it automatically
    // fills up the size of the component as much as it can without overflowing
    // it.
    add(CircleHitbox());
  }

  void ghostDeadScaredScaredIshNormalSequence() {
//FIXME instead of testing this every frame, move into futures, and still test every frame, but only when in the general zone that need to test this
    assert(isGhost);
    if (current == CharacterState.deadGhost) {
      if (world.getNow() - ghostDeadTimeLatest >
          kGhostResetTimeMillis) {
        setUnderlyingBallPosition(
            kGhostStartLocation + Vector2.random() / 100);
        current = CharacterState.scared;
      }
    }
    if (current == CharacterState.scared) {
      if (world.getNow() - ghostScaredTimeLatest >
          kGhostChaseTimeMillis * 2 / 3) {
        current = CharacterState.scaredIsh;
      }
    }

    if (current == CharacterState.scaredIsh) {
      if (world.getNow() - ghostScaredTimeLatest >
          kGhostChaseTimeMillis) {
        current = CharacterState.normal;
      }
    }
  }

  void pacmanEatingNormalSequence() {
    assert(!isGhost);
    if (current == CharacterState.eating) {
      if (world.getNow() - playerEatingTimeLatest >
          2 * kPacmanHalfEatingResetTimeMillis) {
        current = CharacterState.normal;
      }
    }
  }

  Vector2 getFlyingDeadGhostPosition() {
    double timefrac =
        (world.getNow() - ghostDeadTimeLatest) /
            (kGhostResetTimeMillis);
    timefrac = min(1,timefrac);

    return world.screenPos(ghostDeadPosition * (1 - timefrac) + kGhostStartLocation * (timefrac));
  }

  void moveUnderlyingBallThroughPipe() {
    if (!debugMode) {
      if (getUnderlyingBallPosition().x > 10 * getSingleSquareWidth()) {
        setUnderlyingBallPosition(kLeftPortalLocation);
        setUnderlyingVelocity(getUnderlyingBallVelocity());
      } else if (getUnderlyingBallPosition().x < -10 * getSingleSquareWidth()) {
        setUnderlyingBallPosition(kRightPortalLocation);
        setUnderlyingVelocity(getUnderlyingBallVelocity());
      }
    }
  }

  /*
  double oldGetUpdatedAngle() {
    return angle +
        (world.worldAngle - _lastWorldAngle) +
        (getUnderlyingBallPosition() - _lastUnderlyingPosition).length /
            (size.x / 2) *
            getRollSpinDirection(world, getUnderlyingBallVelocity(), world.gravity);
  }
   */

  void updateUnderlyingAngle() {
    underlyingAngle = underlyingAngle +
        (getUnderlyingBallPosition() - _lastUnderlyingPosition).length /
            (size.x / 2) *
            getRollSpinDirection(world, getUnderlyingBallVelocity(), world.gravity);
  }

  double getUpdatedAngle() {
    updateUnderlyingAngle();
    return underlyingAngle + (actuallyMoveSpritesToScreenPos ? world.worldAngle : 0);
  }



  @override
  void update(double dt) {
    super.update(dt);
    //TODO try to capture mouse on windows
    if (isGhost) {
      ghostDeadScaredScaredIshNormalSequence();
    }
    if (!isGhost) {
      pacmanEatingNormalSequence();
    }

    if (globalPhysicsLinked) {
      if (isGhost && current == CharacterState.deadGhost) {
        position = getFlyingDeadGhostPosition();
      } else {
        moveUnderlyingBallThroughPipe();
        position = world.screenPos(getUnderlyingBallPosition());
        angle = getUpdatedAngle();
      }
    }
    _lastUnderlyingPosition.setFrom(getUnderlyingBallPosition());
    //_lastWorldAngle = world.worldAngle;
    _lastUnderlyingVelocity.setFrom(getUnderlyingBallVelocity());
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    handleTwoCharactersMeet(other);
  }

  final Paint _pacmanYellowPaint = Paint()..color = Colors.yellowAccent; //blue; //yellowAccent;
  final Rect rectSingleSquare = Rect.fromCenter(
      center: Offset(getSingleSquareWidth() / 2, getSingleSquareWidth() / 2),
      width: getSingleSquareWidth(),
      height: getSingleSquareWidth());
  final Rect rect100 = Rect.fromCenter(
      center: const Offset(100 / 2, 100 / 2), width: 100, height: 100);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isGhost && current == CharacterState.deadPacman) {
      double tween = 0;
      tween = (world.getNow() - pacmanDeadTimeLatest) /
          kPacmanDeadResetTimeMillis;
      tween = min(1, tween);
      double mouthWidth = 5 / 32 * (1 - tween) + 1 * tween;
      canvas.drawArc(rectSingleSquare, 2 * pi * ((mouthWidth / 2) + 0.5),
          2 * pi * (1 - mouthWidth), true, _pacmanYellowPaint);
    }
  }

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

enum CharacterState { normal, scared, scaredIsh, eating, deadGhost, deadPacman }
