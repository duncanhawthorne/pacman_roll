import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../endless_runner.dart';
import '../endless_world.dart';
import '../constants.dart';
import '../helper.dart';
import 'mini_pellet.dart';
import 'super_pellet.dart';
import 'physics_ball.dart';
import 'dart:math';
import 'dart:ui';
import 'dart:core';
import 'package:flutter/foundation.dart';

/// The [GameCharacter] is the component that the physical player of the game is
/// controlling.
class GameCharacter extends SpriteAnimationGroupComponent<CharacterState>
    with
        CollisionCallbacks,
        HasWorldReference<EndlessWorld>,
        HasGameReference<EndlessRunner> {
  GameCharacter({
    required this.isGhost,
    required this.startingPosition,
    super.position,
  }) : super(
            size: Vector2.all(getSingleSquareWidth()),
            anchor: Anchor.center,
            priority: 1);

  final bool isGhost;
  int ghostNumberForSprite = 1;

  final Vector2 startingPosition;
  late PhysicsBall underlyingBallReal = PhysicsBall(
      realCharacter: this,
      initialPosition: startingPosition); //to avoid null safety issues

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
  // ignore: prefer_final_fields
  Vector2 _lastUnderlyingVelocity = Vector2.zero();

  Future<Map<CharacterState, SpriteAnimation>?> getAnimations() async {
    return isGhost
        ? {
            CharacterState.normal: SpriteAnimation.spriteList(
              [
                await game.loadSprite(ghostNumberForSprite == 0
                    ? 'dash/ghost1.png'
                    : ghostNumberForSprite == 1
                        ? 'dash/ghost2.png'
                        : ghostNumberForSprite == 2
                            ? 'dash/ghost3.png'
                            : [
                                'dash/ghost1.png',
                                'dash/ghost2.png',
                                'dash/ghost3.png'
                              ][world.random.nextInt(3)])
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
                    : Sprite(pacmanStandardImage())
              ],
              stepTime: double.infinity,
            ),
            CharacterState.eating: SpriteAnimation.spriteList(
              [
                kIsWeb
                    ? await game.loadSprite('dash/pacmanman.png')
                    : Sprite(pacmanStandardImage()),
                kIsWeb
                    ? await game.loadSprite('dash/pacmanman_eat.png')
                    : Sprite(pacmanMouthClosedImage())
              ],
              stepTime: kPacmanHalfEatingResetTimeMillis / 1000,
            )
          };
  }

  PhysicsBall createUnderlyingBall(Vector2 targetPosition) {
    PhysicsBall underlyingBallRealTmp =
        PhysicsBall(realCharacter: this, initialPosition: targetPosition);
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
      //FIXME body not initialised. Shouldn't need this, hid error
      //p(["getUnderlyingBallPosition", e]);
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
      //FIXME body not initialised. Shouldn't need this, hid error
      //p(["getUnderlyingBallVelocity", e]);
      return _lastUnderlyingVelocity;
    }
  }

  void setUnderlyingVelocity(Vector2 vel) {
    try {
      underlyingBallReal.body.linearVelocity = vel;
    } catch (e) {
      Future.delayed(const Duration(seconds: 0), () {
        //FIXME body not initialised. Shouldn't need this, hid error
        underlyingBallReal.body.linearVelocity = vel;
      });
    }
  }

  void trimToThreeGhosts() {
    int origNumGhosts = world.ghostPlayersList.length;
    for (int i = 0; i < origNumGhosts; i++) {
      int j = origNumGhosts - 1 - i;
      if (j < 3) {
      } else {
        assert(multipleSpawningGhosts);
        world.removeGhost(world.ghostPlayersList[j]);
      }
    }
  }

  void endOfGameTestAndAct() {
    if (world.pelletsRemaining == 0) {
      world.levelCompleteTimeMillis = world.now;
      int origNumGhosts = world.ghostPlayersList.length;
      for (int i = 0; i < origNumGhosts; i++) {
        int j = origNumGhosts - 1 - i;
        world.ghostPlayersList[j].ghostScaredTimeLatest = 0;
        if (j < 3) {
          world.ghostPlayersList[j].setUnderlyingBallPosition(
              kCageLocation + Vector2.random() / 100);
        } else {
          assert(multipleSpawningGhosts);
          world.removeGhost(world.ghostPlayersList[j]);
        }
      }
      Future.delayed(
          const Duration(milliseconds: kPacmanHalfEatingResetTimeMillis * 2),
          () {
        world.play(SfxType.endMusic);
      });
    }
  }

  void handleTwoCharactersMeet(PositionComponent other) {
    if (!isGhost) {
      //only pacman
      if (other is MiniPellet) {
        if (playerEatingSoundTimeLatest <
            world.now - kPacmanHalfEatingResetTimeMillis * 2) {
          playerEatingSoundTimeLatest = world.now;
          world.play(SfxType.waka);
        }

        current = CharacterState.eating;
        playerEatingTimeLatest = world.now;

        other.removeFromParent();
        world.pelletsRemaining -= 1;
        endOfGameTestAndAct();
      } else if (other is SuperPellet) {
        world.play(SfxType.ghostsScared);
        current = CharacterState.eating;
        playerEatingTimeLatest = world.now;
        for (int i = 0; i < world.ghostPlayersList.length; i++) {
          world.ghostPlayersList[i].current = CharacterState.scared;
          world.ghostPlayersList[i].ghostScaredTimeLatest = world.now;
        }
        other.removeFromParent();
        world.pelletsRemaining -= 1;
        endOfGameTestAndAct();
      } else if (other is GameCharacter) {
        //belts and braces. Already handled by physics collisions in Ball
        handlePacmanMeetsGhost(other);
      }
    }
  }

  void handlePacmanMeetsGhost(GameCharacter otherPlayer) {
    // ignore: unnecessary_this
    if (!this.isGhost && otherPlayer.isGhost) {
      if (otherPlayer.current == CharacterState.deadGhost) {
        //nothing, but need to keep if condition
      } else if (otherPlayer.current == CharacterState.scared ||
          otherPlayer.current == CharacterState.scaredIsh) {
        //pacman eats ghost
        p("pacman eats ghost");

        //pacman visuals
        world.play(SfxType.eatGhost);
        current = CharacterState.eating;
        playerEatingTimeLatest = world.now;

        //ghost impact
        otherPlayer.current = CharacterState.deadGhost;
        otherPlayer.ghostDeadTimeLatest = world.now;
        otherPlayer.ghostDeadPosition = otherPlayer.getUnderlyingBallPosition();
        if (multipleSpawningGhosts) {
          world.removeGhost(otherPlayer);
        } else {
          //Move ball way offscreen. Stops any physics interactions or collisions
          otherPlayer.setUnderlyingBallPosition(kOffScreenLocation +
              Vector2.random() /
                  100); //will get moved to right position later by other code in sequence checker
        }
        if (multipleSpawningPacmans) {
          world.addPacman(getUnderlyingBallPosition() + Vector2.random() / 100);
        }
      } else {
        //ghost kills pacman
        p("ghost kills pacman");
        if (globalPhysicsLinked) {
          //prevent multiple hits

          world.play(SfxType.pacmanDeath);
          pacmanDeadTimeLatest = world.now;
          current = CharacterState.deadPacman;

          if (world.pacmanPlayersList.length == 1) {
            globalPhysicsLinked = false;
            Future.delayed(
                const Duration(milliseconds: kPacmanDeadResetTimeMillis + 100),
                () {
              //100 buffer
              if (!globalPhysicsLinked) {
                //prevent multiple resets

                world.addScore(); //score counting deaths
                setUnderlyingBallPosition(kPacmanStartLocation);
                trimToThreeGhosts();
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
          } else {
            //setUnderlyingBallPosition(kPacmanStartLocation);
            assert(multipleSpawningPacmans);
            Future.delayed(
                const Duration(milliseconds: kPacmanDeadResetTimeMillis),
                () {
              world.removePacman(this);
            });
          }
        }
      }
    }
  }

  void ghostDeadScaredScaredIshNormalSequence() {
    assert(isGhost);
    if (current == CharacterState.deadGhost) {
      if (world.now - ghostDeadTimeLatest > kGhostResetTimeMillis) {
        if (world.pelletsRemaining > 0) {
          setUnderlyingBallPosition(
              kGhostStartLocation + Vector2.random() / 100);
        }
        current = CharacterState.scared;
      }
    }
    if (current == CharacterState.scared) {
      if (world.now - ghostScaredTimeLatest > kGhostChaseTimeMillis * 2 / 3) {
        current = CharacterState.scaredIsh;
      }
    }

    if (current == CharacterState.scaredIsh) {
      if (world.now - ghostScaredTimeLatest > kGhostChaseTimeMillis) {
        current = CharacterState.normal;
        game.audioController.pauseSfx(SfxType.ghostsScared);
      }
    }
  }

  void pacmanEatingNormalSequence() {
    assert(!isGhost);
    if (current == CharacterState.eating) {
      if (world.now - playerEatingTimeLatest >
          2 * kPacmanHalfEatingResetTimeMillis) {
        current = CharacterState.normal;
      }
    }
  }

  Vector2 getFlyingDeadGhostPosition() {
    double timefrac =
        (world.now - ghostDeadTimeLatest) / (kGhostResetTimeMillis);
    timefrac = min(1, timefrac);

    return world.screenPos(
        ghostDeadPosition * (1 - timefrac) + kGhostStartLocation * (timefrac));
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

  void updateUnderlyingAngle() {
    if (useForgePhysicsBallRotation) {
      try {
        underlyingAngle = underlyingBallReal.angle;
      } catch (e) {
        //FIXME body not initialised. Shouldn't need this, hid error
      }
    } else {
      underlyingAngle = underlyingAngle +
          (getUnderlyingBallPosition() - _lastUnderlyingPosition).length /
              (size.x / 2) *
              getRollSpinDirection(
                  world, getUnderlyingBallVelocity(), world.gravity);
    }
  }

  double getUpdatedAngle() {
    updateUnderlyingAngle();
    return underlyingAngle +
        (actuallyMoveSpritesToScreenPos ? world.worldAngle : 0);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    handleTwoCharactersMeet(other);
  }

  @override
  Future<void> onLoad() async {
    setUnderlyingBallPosition(
        startingPosition); //FIXME shouldn't be necessary, but avoids one frame starting glitch

    animations = await getAnimations();
    current = isGhost ? CharacterState.deadGhost : CharacterState.normal;
    _lastUnderlyingPosition.setFrom(getUnderlyingBallPosition());

    // When adding a CircleHitbox without any arguments it automatically
    // fills up the size of the component as much as it can without overflowing
    // it.
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
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
    _lastUnderlyingVelocity.setFrom(getUnderlyingBallVelocity());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isGhost && current == CharacterState.deadPacman) {
      double tween = 0;
      tween = (world.now - pacmanDeadTimeLatest) / kPacmanDeadResetTimeMillis;
      tween = min(1, tween);
      double mouthWidth = 5 / 32 * (1 - tween) + 1 * tween;
      canvas.drawArc(rectSingleSquare, 2 * pi * ((mouthWidth / 2) + 0.5),
          2 * pi * (1 - mouthWidth), true, pacmanYellowPaint);
    }
  }
}

enum CharacterState { normal, scared, scaredIsh, eating, deadGhost, deadPacman }
