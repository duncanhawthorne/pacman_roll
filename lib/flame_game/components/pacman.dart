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
class Pacman extends GameCharacter with CollisionCallbacks {
  Pacman({
    //required this.startPosition,
    required super.position,
  }) : super();

  //final Vector2 startPosition;

  int _pacmanDeadTimeLatest = 0; //a long time ago
  int _pacmanEatingTimeLatest = 0; //a long time ago
  int _pacmanEatingSoundTimeLatest = 0; //a long time ago

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

  void handlePacmanMeetsGhost(Ghost ghost) {
    if (ghost.current == CharacterState.deadGhost) {
      //nothing, but need to keep if condition
    } else if (ghost.current == CharacterState.scared ||
        ghost.current == CharacterState.scaredIsh) {
      pacmanEatsGhost(ghost);
    } else {
      ghostKillsPacman();
    }
  }

  void handleEatingPellets(PositionComponent pellet) {
    if (pellet is MiniPellet) {
      if (_pacmanEatingSoundTimeLatest <
          world.now - kPacmanHalfEatingResetTimeMillis * 2) {
        _pacmanEatingSoundTimeLatest = world.now;
        world.play(SfxType.waka);
      }
    } else {
      world.play(SfxType.ghostsScared);
      for (int i = 0; i < world.ghostPlayersList.length; i++) {
        world.ghostPlayersList[i].current = CharacterState.scared;
        world.ghostPlayersList[i].ghostScaredTimeLatest = world.now;
      }
    }
    current = CharacterState.eating;
    _pacmanEatingTimeLatest = world.now;
    world.removePellet(pellet);
  }

  void pacmanEatsGhost(Ghost ghost) {
    //p("pacman eats ghost");

    //pacman visuals
    world.play(SfxType.eatGhost);
    current = CharacterState.eating;
    _pacmanEatingTimeLatest = world.now;

    //ghost impact
    ghost.current = CharacterState.deadGhost;
    ghost.ghostDeadTimeLatest = world.now;
    ghost.ghostDeadPositionLatest = ghost.getUnderlyingBallPosition();
    if (multipleSpawningGhosts) {
      world.removeGhost(ghost);
    } else {
      //Move ball way offscreen. Stops any physics interactions or collisions
      ghost.setUnderlyingBallPosition(kOffScreenLocation +
          Vector2.random() /
              100); //will get moved to right position later by other code in sequence checker
    }
    if (multipleSpawningPacmans) {
      world.addPacman(getUnderlyingBallPosition() + Vector2.random() / 100);
    }
  }

  void ghostKillsPacman() {
    //p("ghost kills pacman");
    if (globalPhysicsLinked) {
      //prevent multiple hits

      world.play(SfxType.pacmanDeath);
      _pacmanDeadTimeLatest = world.now;
      current = CharacterState.deadPacman;

      if (world.pacmanPlayersList.length == 1) {
        globalPhysicsLinked = false;
        Future.delayed(
            const Duration(milliseconds: kPacmanDeadResetTimeMillis + 100), () {
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
        Future.delayed(const Duration(milliseconds: kPacmanDeadResetTimeMillis),
            () {
          world.removePacman(this);
        });
      }
    }
  }

  void pacmanEatingNormalSequence() {
    if (current == CharacterState.eating) {
      if (world.now - _pacmanEatingTimeLatest >
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
    setUnderlyingBallPosition(position); //FIXME shouldn't be necessary, but avoids one frame starting glitch
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
      assert(world.now >= _pacmanDeadTimeLatest);
      double tween = (world.now - _pacmanDeadTimeLatest) / kPacmanDeadResetTimeMillis;
      tween = min(1, tween);
      double mouthWidth = pacmanMouthWidthDefault * (1 - tween) + 1 * tween;
      canvas.drawArc(rectSingleSquare, 2 * pi * ((mouthWidth / 2) + 0.5),
          2 * pi * (1 - mouthWidth), true, pacmanYellowPaint);
    }
  }
}
