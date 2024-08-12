import 'dart:core';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../audio/sounds.dart';
import '../effects/move_to_effect.dart';
import '../effects/null_effect.dart';
import '../icons/pacman_sprites.dart';
import '../maze.dart';
import 'game_character.dart';
import 'ghost.dart';
import 'pellet.dart';
import 'super_pellet.dart';

const int _kPacmanDeadResetTimeMillis = 1700;
const int _kPacmanHalfEatingResetTimeMillis = 180;
const _multipleSpawningPacmans = false;

/// The [GameCharacter] is the component that the physical player of the game is
/// controlling.
class Pacman extends GameCharacter with CollisionCallbacks {
  Pacman({
    required super.position,
  }) : super(priority: 2);

  int _pacmanStartEatingTimeLatest = 0; //a long time ago
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
          loop: false),
      CharacterState.dead: SpriteAnimation.spriteList(
          await pacmanSprites.pacmanDyingSprites(size),
          stepTime:
              kPacmanDeadResetTimeAnimationMillis / 1000 / pacmanDeadFrames,
          loop: false),
      CharacterState.spawning: SpriteAnimation.spriteList(
          await pacmanSprites.pacmanBirthingSprites(size),
          stepTime: kResetPositionTimeMillis / 1000 / pacmanDeadFrames,
          loop: false)
    };
  }

  void _eat({required isPellet}) {
    if (typical) {
      if (current == CharacterState.normal) {
        current = CharacterState.eating;
        _pacmanStartEatingTimeLatest = game.now;
        if (isPellet) {
          world.play(SfxType.waka);
        } else {
          world.play(SfxType.eatGhost);
        }
      }
      //if in eating state, just let that sequence complete normally
    }
  }

  void _onCollideWith(PositionComponent other) {
    if (typical) {
      if (other is Pellet) {
        _onCollideWithPellet(other);
      } else if (other is Ghost) {
        _onCollideWithGhost(other);
      }
    }
  }

  void _onCollideWithPellet(Pellet pellet) {
    if (typical) {
      // can simultaneously eat pellet and die to ghost so don't want to do this if just died
      pellet.removeFromParent(); //do this first, for checks based on game over
      if (pellet is SuperPellet) {
        world.ghosts.scareGhosts();
      }
      _eat(isPellet: true);
    }
  }

  void _onCollideWithGhost(Ghost ghost) {
    if (typical && ghost.typical) {
      if (ghost.current == CharacterState.scared ||
          ghost.current == CharacterState.scaredIsh) {
        _eatGhost(ghost);
      } else {
        _dieFromGhost();
      }
    }
  }

  void _eatGhost(Ghost ghost) {
    if (typical && ghost.typical) {
      _eat(isPellet: false);
      ghost.setDead();
      if (_multipleSpawningPacmans) {
        world.pacmans.add(Pacman(position: position + Vector2.random() / 100));
      }
    }
  }

  static const bool _freezeGhostsOnKillPacman = false;
  void _dieFromGhost() {
    if (typical) {
      if (world.pellets.pelletsRemainingNotifier.value != 0) {
        world.play(SfxType.pacmanDeath);
        current = CharacterState.dead;
        disconnectFromBall();
        if (_freezeGhostsOnKillPacman) {
          world.ghosts.disconnectGhostsFromBalls();
        }
        world.pacmans.pacmanDyingNotifier.value++;
        if (world.pacmans.pacmanList.length == 1 ||
            world.pacmans.numberAlivePacman() == 0) {
          world.doingLevelResetFlourish = true;
          game.stopwatch.stop();
          world.ghosts.cancelMultiGhostAdderTimer();
        }
        add(NullEffect(_kPacmanDeadResetTimeMillis,
            onComplete: _dieFromGhostActionAfterDeathAnimation));
      }
    }
  }

  void _dieFromGhostActionAfterDeathAnimation() {
    if (current == CharacterState.dead && !world.gameWonOrLost) {
      if (world.pacmans.pacmanList.length == 1 ||
          world.pacmans.numberAlivePacman() == 0) {
        world.pacmans.numberOfDeathsNotifier.value++; //score counting deaths
        world.resetAfterPacmanDeath(this);
      } else {
        assert(_multipleSpawningPacmans);
        disconnectFromBall(); //sync //already done, but keep
        removeFromParent(); //async
      }
    }
  }

  void resetSlideAfterDeath() {
    removeWhere((item) => item is Effect);
    setPositionStill(maze.pacmanStart);
    disconnectFromBall();
    angle = 0;
    current = CharacterState.spawning;
  }

  void resetInstantAfterDeath() {
    removeWhere((item) => item is Effect);
    setPositionStill(maze.pacmanStart);
    angle = 0;
    current = CharacterState.normal;
  }

  void _stateSequence() {
    if (current == CharacterState.eating) {
      if (game.now - _pacmanStartEatingTimeLatest >
          _kPacmanHalfEatingResetTimeMillis * 2) {
        current = CharacterState.normal;
      }
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    world.pacmans.pacmanList.add(this);
    current = CharacterState.normal;
    angle = 0;
  }

  @override
  Future<void> onGameResize(Vector2 size) async {
    super.onGameResize(size);
    if (size.x != _screenSizeLast.x || size.y != _screenSizeLast.y) {
      _screenSizeLast.setFrom(size);
      animations = await _getAnimations(2 * maze.spriteWidthOnScreen(size));
    }
  }

  @override
  Future<void> onRemove() async {
    world.pacmans.pacmanList.remove(this);
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
    _stateSequence();
    super.update(dt);
  }
}
