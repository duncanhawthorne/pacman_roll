import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../constants.dart';
import '../helper.dart';
import 'mini_pellet.dart';
import 'super_pellet.dart';
import 'pacman_sprites.dart';
import 'ghost.dart';
import 'game_character.dart';
import 'dart:math';
import 'dart:core';

/// The [GameCharacter] is the component that the physical player of the game is
/// controlling.
class Pacman extends GameCharacter with CollisionCallbacks {
  Pacman({
    required super.position,
  }) : super();

  int _pacmanSpecialStartEatingTimeLatest = 0; //a long time ago
  int _targetRoundedMouthOpenTime = 0; //a long time ago
  int _pacmanEatingTimeLatest = 0; //a long time ago
  int _pacmanEatingSoundTimeLatest = 0; //a long time ago

  Future<Map<CharacterState, SpriteAnimation>?> getAnimations() async {
    return {
      CharacterState.normal: SpriteAnimation.spriteList(
        [await pacmanAtFrac(pacmanMouthWidthDefault)],
        stepTime: double.infinity,
      ),
      CharacterState.eating: SpriteAnimation.spriteList(
        await pacmanEatingSprites(),
        stepTime:
            kPacmanHalfEatingResetTimeMillis / 1000 / pacmanEatingHalfFrames,
      ),
      CharacterState.deadPacman: SpriteAnimation.spriteList(
          await pacmanDyingSprites(),
          stepTime:
              kPacmanDeadResetTimeAnimationMillis / 1000 / pacmanDeadFrames,
          loop: false)
    };
  }

  void eat() {
    if (current != CharacterState.eating) {
      //first time
      _pacmanSpecialStartEatingTimeLatest = world.now;
    }
    current = CharacterState.eating;
    _pacmanEatingTimeLatest = world.now;

    int unroundedMouthOpenTime =
        2 * kPacmanHalfEatingResetTimeMillis + _pacmanEatingTimeLatest;

    //ensure animation end synced up with turned off eating state, so move forward time by a few milliseconds
    _targetRoundedMouthOpenTime = roundUpToMult(
            unroundedMouthOpenTime - _pacmanSpecialStartEatingTimeLatest,
            2 * kPacmanHalfEatingResetTimeMillis) +
        _pacmanSpecialStartEatingTimeLatest;
  }

  void handleTwoCharactersMeet(PositionComponent other) {
    if (other is MiniPellet ||
        other is SuperPellet ||
        other is MiniPelletCircle ||
        other is SuperPelletCircle) {
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
    if (current != CharacterState.deadPacman) {
      // can simultaneously eat pellet and die to ghost so don't want to do this if just died
      if (pellet is MiniPellet || pellet is MiniPelletCircle) {
        if (_pacmanEatingSoundTimeLatest <
            world.now - kPacmanHalfEatingResetTimeMillis * 2) {
          _pacmanEatingSoundTimeLatest = world.now;
          world.play(SfxType.waka);
        }
      } else {
        world.play(SfxType.ghostsScared);
        for (int i = 0; i < world.ghostPlayersList.length; i++) {
          world.ghostPlayersList[i].setScared();
        }
      }
      eat();
      world.remove(pellet);
    }
  }

  void pacmanEatsGhost(Ghost ghost) {
    //pacman visuals
    world.play(SfxType.eatGhost);
    eat();

    //ghost impact
    ghost.setDead();

    //other impact
    if (multipleSpawningPacmans) {
      //world.addPacman(getUnderlyingBallPosition() + Vector2.random() / 100);
      world.add(Pacman(position: position + Vector2.random() / 100));
    }
  }

  void ghostKillsPacman() {
    if (world.physicsOn) {
      //prevent multiple hits

      world.play(SfxType.pacmanDeath);
      current = CharacterState.deadPacman;

      if (world.pacmanPlayersList.length == 1) {
        world.physicsOn = false;
        Future.delayed(
            const Duration(milliseconds: kPacmanDeadResetTimeMillis + 100), () {
          //100 buffer
          if (!world.physicsOn) {
            //prevent multiple resets

            world.addDeath(); //score counting deaths
            setPosition(kPacmanStartLocation);
            world.trimToThreeGhosts();
            for (var i = 0; i < world.ghostPlayersList.length; i++) {
              world.ghostPlayersList[i].setStartPositionAfterPacmanDeath();
            }
            current = CharacterState.normal;
            world.physicsOn = true;
          }
        });
      } else {
        assert(multipleSpawningPacmans);
        Future.delayed(const Duration(milliseconds: kPacmanDeadResetTimeMillis),
            () {
          world.remove(this);
        });
      }
    }
  }

  void pacmanEatingNormalSequence() {
    if (current == CharacterState.eating) {
      if (world.now > _targetRoundedMouthOpenTime) {
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
    super.onLoad();
    world.pacmanPlayersList.add(this);
    animations = await getAnimations();
    current = CharacterState.normal;
    angle = 2 * pi / 2;
  }

  @override
  Future<void> onRemove() async {
    world.pacmanPlayersList.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    pacmanEatingNormalSequence();

    if (world.physicsOn) {
      oneFrameOfPhysics();
    }

    super.update(dt);
  }
}
