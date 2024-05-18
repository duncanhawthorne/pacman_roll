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
        [pacmanSpriteAtFrac(pacmanMouthWidthDefault)],
        stepTime: double.infinity,
      ),
      CharacterState.eating: SpriteAnimation.spriteList(
        List<Sprite>.generate(
            pacmanEatingHalfFrames * 2, //open and close
            (int index) => pacmanSpriteAtFrac(pacmanMouthWidthDefault -
                pacmanMouthWidthDefault *
                    ((index < pacmanEatingHalfFrames
                            ? index
                            : pacmanEatingHalfFrames -
                                (index - pacmanEatingHalfFrames)) /
                        pacmanEatingHalfFrames)),
            growable: true),
        stepTime:
            kPacmanHalfEatingResetTimeMillis / 1000 / pacmanEatingHalfFrames,
      ),
      CharacterState.deadPacman: SpriteAnimation.spriteList(
        List<Sprite>.generate(
            (pacmanDeadFrames *
                    kPacmanDeadResetTimeMillis /
                    kPacmanDeadResetTimeAnimationMillis *
                    1.2)
                .toInt(), //buffer for sound effect time difference
            (int index) => pacmanSpriteAtFrac(pacmanMouthWidthDefault +
                (1 - pacmanMouthWidthDefault) * (index / pacmanDeadFrames)),
            growable: true),
        stepTime: kPacmanDeadResetTimeAnimationMillis / 1000 / pacmanDeadFrames,
      )
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
    if (pellet is MiniPellet || pellet is MiniPelletCircle) {
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
    eat();
    world.remove(pellet);
  }

  void pacmanEatsGhost(Ghost ghost) {
    //p("pacman eats ghost");

    //pacman visuals
    world.play(SfxType.eatGhost);
    eat();

    //ghost impact
    ghost.current = CharacterState.deadGhost;
    ghost.add(ReturnHomeEffect(kGhostStartLocation));
    ghost.ghostDeadTimeLatest = world.now;
    if (multipleSpawningGhosts) {
      world.remove(ghost);
    } else {
      //Move ball way offscreen. Stops any physics interactions or collisions
      ghost.setUnderlyingBallPosition(kOffScreenLocation +
          Vector2.random() /
              100); //will get moved to right position later by other code in sequence checker
      //ghost.setUnderlyingBallStatic();
    }
    if (multipleSpawningPacmans) {
      //world.addPacman(getUnderlyingBallPosition() + Vector2.random() / 100);
      world.add(Pacman(position: position + Vector2.random() / 100));
    }
  }

  void ghostKillsPacman() {
    //p("ghost kills pacman");
    if (world.globalPhysicsLinked) {
      //prevent multiple hits

      world.play(SfxType.pacmanDeath);
      current = CharacterState.deadPacman;

      if (world.pacmanPlayersList.length == 1) {
        world.globalPhysicsLinked = false;
        Future.delayed(
            const Duration(milliseconds: kPacmanDeadResetTimeMillis + 100), () {
          //100 buffer
          if (!world.globalPhysicsLinked) {
            //prevent multiple resets

            world.addDeath(); //score counting deaths
            setPosition(kPacmanStartLocation);
            world.trimToThreeGhosts();
            for (var i = 0; i < world.ghostPlayersList.length; i++) {
              world.ghostPlayersList[i]
                  .setPosition(kGhostStartLocation + Vector2.random() / 100);
              world.ghostPlayersList[i].ghostDeadTimeLatest = 0;
              world.ghostPlayersList[i].ghostScaredTimeLatest = 0;
            }
            current = CharacterState.normal;
            world.globalPhysicsLinked = true;
          }
        });
      } else {
        //setUnderlyingBallPosition(kPacmanStartLocation);
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

    if (world.globalPhysicsLinked) {
      oneFrameOfPhysics();
    }

    super.update(dt);
  }
}
