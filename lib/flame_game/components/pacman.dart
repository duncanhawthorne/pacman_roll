import 'dart:async';
import 'dart:core';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../effects/move_to_effect.dart';
import '../effects/null_effect.dart';
import '../effects/remove_effects.dart';
import '../icons/pacman_sprites.dart';
import '../maze.dart';
import 'clones.dart';
import 'game_character.dart';
import 'ghost.dart';
import 'pellet.dart';
import 'super_pellet.dart';

const int _kPacmanDeadResetTimeMillis = 1700;
const int _kPacmanHalfEatingResetTimeMillis = 180;
const bool _multipleSpawningPacmans = false;

/// The [GameCharacter] is the component that the physical player of the game is
/// controlling.
class Pacman extends GameCharacter with CollisionCallbacks {
  Pacman({required super.position, super.original});

  final Vector2 _screenSizeLast = Vector2(0, 0);
  final Timer _eatTimer = Timer(_kPacmanHalfEatingResetTimeMillis * 2 / 1000);

  @override
  Future<Map<CharacterState, SpriteAnimation>?> getAnimations(
      [int size = 1]) async {
    return <CharacterState, SpriteAnimation>{
      CharacterState.normal: SpriteAnimation.spriteList(
        await pacmanSprites.pacmanNormalSprites(size),
        stepTime: double.infinity,
      ),
      CharacterState.eating: SpriteAnimation.spriteList(
          await pacmanSprites.pacmanEatingSprites(size),
          stepTime: _kPacmanHalfEatingResetTimeMillis /
              1000 /
              pacmanEatingHalfIncrements,
          loop: false),
      CharacterState.dead: SpriteAnimation.spriteList(
          await pacmanSprites.pacmanDyingSprites(size),
          stepTime:
              kPacmanDeadResetTimeAnimationMillis / 1000 / pacmanDeadIncrements,
          loop: false),
      CharacterState.spawning: SpriteAnimation.spriteList(
          await pacmanSprites.pacmanBirthingSprites(size),
          stepTime: kResetPositionTimeMillis / 1000 / pacmanDeadIncrements,
          loop: false)
    };
  }

  void _eat({required bool isPellet}) {
    if (typical) {
      if (current == CharacterState.normal) {
        current = CharacterState.eating;
        _eatTimer.start();
        if (isPellet) {
          world.play(SfxType.waka);
        } else {
          world.play(SfxType.eatGhost);
        }
      }
      //if in eating state, just let that sequence complete normally
    }
  }

  void onCollideWith(PositionComponent other) {
    if (this is PacmanClone) {
      (original! as Pacman).onCollideWith(other);
      return;
    }
    if (typical) {
      if (other is Pellet) {
        _onCollideWithPellet(other);
      } else if (other is Ghost && other is! GhostClone) {
        _onCollideWithGhost(other);
      } else if (other is GhostClone) {
        _onCollideWithGhost(other.original! as Ghost);
      }
    }
  }

  void _onCollideWithPellet(Pellet pellet) {
    if (typical) {
      // can simultaneously eat pellet and die to ghost
      // so don't want to do this if just died
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
          game.stopwatch.pause();
          world.ghosts.removeSpawner();
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
        if (world.doingLevelResetFlourish) {
          // must test doingLevelResetFlourish
          // as could have been removed by reset during delay
          world.pacmans.numberOfDeathsNotifier.value++; //score counting deaths
          world.resetAfterPacmanDeath(this);
        }
      } else {
        assert(_multipleSpawningPacmans);
        //possible bug here if two pacmans are removed in quick succession
        removeFromParent();
      }
    }
  }

  void resetSlideAfterDeath() {
    removeEffects(this);
    setPositionStill(maze.pacmanStart);
    disconnectFromBall();
    angle = 0;
    current = CharacterState.spawning;
  }

  void resetInstantAfterDeath() {
    removeEffects(this);
    setPositionStill(maze.pacmanStart);
    angle = 0;
    current = CharacterState.normal;
  }

  void _stateSequence(double dt) {
    if (isClone) {
      return;
    }
    _eatTimer.update(dt);
    if (current == CharacterState.eating) {
      if (_eatTimer.finished) {
        current = CharacterState.normal;
        _eatTimer.pause(); //makes update function for timer free
      }
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (!isClone) {
      world.pacmans.pacmanList.add(this);
      current = CharacterState.normal;
      clone = PacmanClone(position: position, original: this);
    }
  }

  @override
  Future<void> onGameResize(Vector2 size) async {
    if (size.x != _screenSizeLast.x || size.y != _screenSizeLast.y) {
      _screenSizeLast.setFrom(size);
      animations = await getAnimations(2 * maze.spriteWidthOnScreen(size));
    }
    super.onGameResize(size);
  }

  @override
  Future<void> onRemove() async {
    if (!isClone) {
      world.pacmans.pacmanList.remove(this);
    }
    unawaited(super.onRemove());
  }

  @override
  void onCollision(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    onCollideWith(other);
    super.onCollision(intersectionPoints, other);
  }

  @override
  void update(double dt) {
    //note, this function is also run for clones
    _stateSequence(dt);
    super.update(dt);
  }
}
