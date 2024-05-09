import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../constants.dart';
import '../helper.dart';
import 'mini_pellet.dart';
import 'super_pellet.dart';
import 'ghost.dart';
import 'game_character.dart';
import 'dart:math';
import 'dart:ui';
import 'dart:core';
import 'package:flutter/foundation.dart';

/// The [GameCharacter] is the component that the physical player of the game is
/// controlling.
class Pacman extends GameCharacter {
  Pacman({
    required this.startPosition,
    super.position,
  }) : super(startingPosition: startPosition);

  final Vector2 startPosition;

  int pacmanDeadTimeLatest = 0; //a long time ago
  int pacmanEatingTimeLatest = 0; //a long time ago
  int pacmanEatingSoundTimeLatest = 0; //a long time ago

  Future<Map<CharacterState, SpriteAnimation>?> getAnimations() async {
    return {
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

  void handleTwoCharactersMeet(PositionComponent other) {
    if (other is MiniPellet || other is SuperPellet) {
      handleEatingPellets(other);
    } else if (other is Ghost) {
      //belts and braces. Already handled by physics collisions in Ball //FIXME actually not now
      handlePacmanMeetsGhost(other);
    }
  }

  void handleEatingPellets(PositionComponent other) {
    if (other is MiniPellet) {
      if (pacmanEatingSoundTimeLatest <
          world.now - kPacmanHalfEatingResetTimeMillis * 2) {
        pacmanEatingSoundTimeLatest = world.now;
        world.play(SfxType.waka);
      }
    } else {
      world.play(SfxType.ghostsScared);
    }
    current = CharacterState.eating;
    pacmanEatingTimeLatest = world.now;
    if (other is SuperPellet) {
      for (int i = 0; i < world.ghostPlayersList.length; i++) {
        world.ghostPlayersList[i].current = CharacterState.scared;
        world.ghostPlayersList[i].ghostScaredTimeLatest = world.now;
      }
    }
    other.removeFromParent();
    world.pelletsRemaining -= 1;
    world.endOfGameTestAndAct(world);
  }

  void handlePacmanMeetsGhost(Ghost otherPlayer) {
    // ignore: unnecessary_this
    if (true) {
      if (otherPlayer.current == CharacterState.deadGhost) {
        //nothing, but need to keep if condition
      } else if (otherPlayer.current == CharacterState.scared ||
          otherPlayer.current == CharacterState.scaredIsh) {
        //pacman eats ghost
        p("pacman eats ghost");

        //pacman visuals
        world.play(SfxType.eatGhost);
        current = CharacterState.eating;
        pacmanEatingTimeLatest = world.now;

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
                world.trimToThreeGhosts();
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
                const Duration(milliseconds: kPacmanDeadResetTimeMillis), () {
              world.removePacman(this);
            });
          }
        }
      }
    }
  }

  void pacmanEatingNormalSequence() {
    if (current == CharacterState.eating) {
      if (world.now - pacmanEatingTimeLatest >
          2 * kPacmanHalfEatingResetTimeMillis) {
        current = CharacterState.normal;
      }
    }
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
    animations = await getAnimations();
    setUnderlyingBallPosition(
        startingPosition); //FIXME shouldn't be necessary, but avoids one frame starting glitch
    current = CharacterState.normal;

    // When adding a CircleHitbox without any arguments it automatically
    // fills up the size of the component as much as it can without overflowing
    // it.
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    pacmanEatingNormalSequence();

    if (globalPhysicsLinked) {
      oneFrameOfPhysics();
    }

    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (current == CharacterState.deadPacman) {
      double tween = 0;
      tween = (world.now - pacmanDeadTimeLatest) / kPacmanDeadResetTimeMillis;
      tween = min(1, tween);
      double mouthWidth = 5 / 32 * (1 - tween) + 1 * tween;
      canvas.drawArc(rectSingleSquare, 2 * pi * ((mouthWidth / 2) + 0.5),
          2 * pi * (1 - mouthWidth), true, pacmanYellowPaint);
    }
  }
}
