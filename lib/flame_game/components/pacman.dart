import 'dart:core';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../icons/pacman_sprites.dart';
import 'game_character.dart';
import 'ghost.dart';
import 'maze.dart';
import 'mini_pellet.dart';
import 'super_pellet.dart';

const int _kPacmanDeadResetTimeMillis = 1700;
const int kPacmanDeadResetTimeAnimationMillis = 1250;
const int _kPacmanHalfEatingResetTimeMillis = 180;
const multipleSpawningPacmans = false;

/// The [GameCharacter] is the component that the physical player of the game is
/// controlling.
class Pacman extends GameCharacter with CollisionCallbacks {
  Pacman({
    required super.position,
  }) : super(priority: 2);

  int _pacmanSpecialStartEatingTimeLatest = 0; //a long time ago
  int _targetRoundedMouthOpenTime = 0; //a long time ago
  int _pacmanEatingTimeLatest = 0; //a long time ago
  int _pacmanEatingSoundTimeLatest = 0; //a long time ago
  final Vector2 _screenSizeLast = Vector2(0, 0);

  Future<Map<CharacterState, SpriteAnimation>?> _getAnimations(int size) async {
    return {
      CharacterState.normal: SpriteAnimation.spriteList(
        await pacmanSprites.pacmanNormalSprites(size),
        stepTime: double.infinity,
      ),
      CharacterState.eating: SpriteAnimation.spriteList(
        await pacmanSprites.pacmanEatingSprites(size),
        stepTime:
            _kPacmanHalfEatingResetTimeMillis / 1000 / pacmanEatingHalfFrames,
      ),
      CharacterState.deadPacman: SpriteAnimation.spriteList(
          await pacmanSprites.pacmanDyingSprites(size),
          stepTime:
              kPacmanDeadResetTimeAnimationMillis / 1000 / pacmanDeadFrames,
          loop: false),
      CharacterState.birthing: SpriteAnimation.spriteList(
          await pacmanSprites.pacmanBirthingSprites(size),
          stepTime: kGhostResetTimeMillis / 1000 / pacmanDeadFrames,
          loop: false)
    };
  }

  void _eatAnimation() {
    if (current != CharacterState.deadPacman) {
      if (current != CharacterState.eating) {
        //first time
        _pacmanSpecialStartEatingTimeLatest = world.now;
      }
      current = CharacterState.eating;
      _pacmanEatingTimeLatest = world.now;

      int unroundedMouthOpenTime =
          2 * _kPacmanHalfEatingResetTimeMillis + _pacmanEatingTimeLatest;

      //ensure animation end synced up with turned off eating state, so move forward time by a few milliseconds
      _targetRoundedMouthOpenTime = roundUpToMult(
              unroundedMouthOpenTime - _pacmanSpecialStartEatingTimeLatest,
              2 * _kPacmanHalfEatingResetTimeMillis) +
          _pacmanSpecialStartEatingTimeLatest;
    }
  }

  void _eatPelletSound() {
    if (!world.gameWonOrLost) {
      if (_pacmanEatingSoundTimeLatest <
          world.now - _kPacmanHalfEatingResetTimeMillis * 2) {
        _pacmanEatingSoundTimeLatest = world.now;
        world.play(SfxType.waka);
      }
    }
  }

  void _onCollideWith(PositionComponent other) {
    if (current != CharacterState.deadPacman) {
      if (other is MiniPelletSprite ||
          other is SuperPelletSprite ||
          other is MiniPelletCircle ||
          other is SuperPelletCircle) {
        _onCollideWithPellet(other);
      } else if (other is Ghost) {
        //If turn on collision callbacks in physicsBall this would be belt and braces. Right now not
        _onCollideWithGhost(other);
      }
    }
  }

  void _onCollideWithPellet(PositionComponent pellet) {
    if (current != CharacterState.deadPacman) {
      // can simultaneously eat pellet and die to ghost so don't want to do this if just died
      world.remove(pellet); //do this first so checks based on game over apply
      if (pellet is MiniPelletSprite || pellet is MiniPelletCircle) {
        _eatPelletSound();
      } else {
        //superPellet
        world.scareGhosts();
      }
      _eatAnimation();
    }
  }

  void _onCollideWithGhost(Ghost ghost) {
    if (ghost.current == CharacterState.deadGhost ||
        current == CharacterState.deadPacman ||
        !connectedToBall ||
        !ghost.connectedToBall) {
      //nothing, but need to keep if condition
    } else if (ghost.current == CharacterState.scared ||
        ghost.current == CharacterState.scaredIsh) {
      _eatGhost(ghost);
    } else {
      _dieFromGhost();
    }
  }

  void _eatGhost(Ghost ghost) {
    if (current != CharacterState.deadPacman) {
      //pacman visuals
      world.play(SfxType.eatGhost);
      _eatAnimation();

      //ghost impact
      ghost.setDead();

      //other impact
      if (multipleSpawningPacmans) {
        //world.addPacman(getUnderlyingBallPosition() + Vector2.random() / 100);
        world.add(Pacman(position: position + Vector2.random() / 100));
      }
    }
  }

  void _dieFromGhost() {
    if (current != CharacterState.deadPacman &&
        world.pelletsRemainingNotifier.value != 0) {
      world.play(SfxType.pacmanDeath);
      current = CharacterState.deadPacman;
      disconnectFromPhysics();
      //world.disconnectGhostsFromPhysics();
      world.pacmanDyingNotifier.value++;

      Future.delayed(
          const Duration(milliseconds: _kPacmanDeadResetTimeMillis + 100), () {
        if (world.pacmanPlayersList.length == 1 ||
            world.numberAlivePacman() == 0) {
          world.numberOfDeathsNotifier.value++; //score counting deaths
          world.resetWorldAfterPacmanDeath(this);
        } else {
          assert(multipleSpawningPacmans);
          world.remove(this);
        }
      });
    }
  }

  void setStartPositionAfterDeath() {
    setPositionStill(maze.pacmanStart);
    angle = 2 * pi / 2;
    current = CharacterState.normal;
  }

  void slideToStartPositionAfterDeath() {
    setPositionStill(maze.pacmanStart);
    disconnectFromPhysics();
    angle = 2 * pi / 2;
    current = CharacterState.birthing;
  }

  void _pacmanEatingNormalSequence() {
    if (current == CharacterState.eating) {
      if (world.now > _targetRoundedMouthOpenTime) {
        current = CharacterState.normal;
      }
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    world.pacmanPlayersList.add(this);
    current = CharacterState.normal;
    angle = 2 * pi / 2;
  }

  @override
  Future<void> onGameResize(Vector2 size) async {
    if (size.x != _screenSizeLast.x || size.y != _screenSizeLast.y) {
      _screenSizeLast.setFrom(size);
      animations = await _getAnimations(2 * maze.spriteWidthOnScreen(size));
    }
    super.onGameResize(size);
  }

  @override
  Future<void> onRemove() async {
    world.pacmanPlayersList.remove(this);
    super.onRemove();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    _onCollideWith(other);
  }

  @override
  void update(double dt) {
    _pacmanEatingNormalSequence();
    super.update(dt);
  }
}

int roundUpToMult(int x, int roundUpMult) {
  return (x / roundUpMult).ceil() * roundUpMult;
}
