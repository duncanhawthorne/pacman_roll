import 'dart:core';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../effects/move_to_effect.dart';
import '../effects/null_effect.dart';
import '../effects/remove_effects.dart';
import '../icons/pacman_sprites.dart';
import '../maze.dart';
import '../pacman_world.dart';
import 'clones.dart';
import 'game_character.dart';
import 'ghost.dart';
import 'pellet.dart';
import 'sprite_character.dart';
import 'super_pellet.dart';
import 'wall.dart';
import 'wall_dynamic_layer.dart';

const int _kPacmanDeadResetTimeMillis = 1550;
const int _kPacmanHalfEatingResetTimeMillis = 180;
const bool multipleSpawningPacmans = false;
const bool _freezeGhostsOnKillPacman = false;

/// The [GameCharacter] is the component that the physical player of the game is
/// controlling.
class Pacman extends GameCharacter with CollisionCallbacks {
  Pacman({required super.position, super.original})
    : super(velocity: Vector2.zero(), radius: playerSize);

  final Vector2 _screenSizeLast = Vector2(0, 0);
  final Timer _eatTimer = Timer(_kPacmanHalfEatingResetTimeMillis * 2 / 1000);

  @override
  Future<Map<CharacterState, SpriteAnimation>> getAnimations([
    int size = 1,
  ]) async {
    return <CharacterState, SpriteAnimation>{
      CharacterState.normal: SpriteAnimation.spriteList(
        await pacmanSprites.pacmanNormalSprites(size),
        stepTime: double.infinity,
      ),
      CharacterState.eating: SpriteAnimation.spriteList(
        await pacmanSprites.pacmanEatingSprites(size),
        stepTime:
            _kPacmanHalfEatingResetTimeMillis /
            1000 /
            pacmanEatingHalfIncrements,
        loop: false,
      ),
      CharacterState.dead: SpriteAnimation.spriteList(
        await pacmanSprites.pacmanDyingSprites(size),
        stepTime:
            kPacmanDeadResetTimeAnimationMillis / 1000 / pacmanDeadIncrements,
        loop: false,
      ),
      CharacterState.spawning: SpriteAnimation.spriteList(
        await pacmanSprites.pacmanBirthingSprites(size),
        stepTime: kResetPositionTimeMillis / 1000 / pacmanDeadIncrements,
        loop: false,
      ),
    };
  }

  void _eat({required bool isPellet}) {
    if (typical) {
      if (current == CharacterState.normal) {
        current = CharacterState.eating;
        _eatTimer.start();
        if (isPellet) {
          //only play waka if not recently played waka
          world.play(SfxType.waka);
        }
      }
      if (!isPellet) {
        //play eatGhost irrespective of current state
        world.play(SfxType.eatGhost);
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
      } else if (PacmanWorld.enableMovingWalls &&
          movingWallsDamage &&
          other is MovingWallWrapper) {
        _dieFromGhost();
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
      if (multipleSpawningPacmans) {
        world.pacmans.add(Pacman(position: position + Vector2.random() / 100));
      }
    }
  }

  void _dieFromGhost() {
    if (world.doingLevelResetFlourish) {
      // avoid race condition
      // already doing a level reset flourish from somewhere else
      return;
    }
    if (typical) {
      if (!game.isWonOrLost) {
        world.play(SfxType.pacmanDeath);
        current = CharacterState.dead;
        setPhysicsState(PhysicsState.none);
        if (_freezeGhostsOnKillPacman) {
          world.ghosts.disconnectGhostsFromBalls();
        }
        world.pacmans.pacmanDyingNotifier.value++;
        if (world.pacmans.pacmanDeathIsFinalPacman) {
          world.doingLevelResetFlourish = true;
          game.stopRegularItems();
        }
        add(
          NullEffect(
            _kPacmanDeadResetTimeMillis,
            onComplete: _dieFromGhostActionAfterDeathAnimation,
          ),
        );
      }
    }
  }

  void _dieFromGhostActionAfterDeathAnimation() {
    if (current == CharacterState.dead && !game.isWonOrLost) {
      if (world.pacmans.pacmanDeathIsFinalPacman) {
        if (world.doingLevelResetFlourish) {
          // must test doingLevelResetFlourish
          // as could have been removed by reset during delay
          game.numberOfDeathsNotifier.value++; //score counting deaths
          world.resetAfterPacmanDeath(this);
        }
      } else {
        assert(multipleSpawningPacmans);
        //possible bug here if two pacmans are removed in quick succession
        removeFromParent();
      }
    }
  }

  void resetSlideAfterDeath() {
    removeEffects(this);
    setPositionStillStatic(maze.pacmanStart);
    angle = 0;
    current = CharacterState.spawning;
  }

  void resetInstantAfterDeath() {
    removeEffects(this);
    setPositionStillActive(maze.pacmanStart);
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
    if (!isClone) {
      setPhysicsState(PhysicsState.full, starting: true);
    }
    await super.onLoad();
    if (!isClone) {
      world.pacmans.pacmanList.add(this);
      current = CharacterState.normal;
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
  void removalActions() {
    if (!isClone) {
      world.pacmans.pacmanList.remove(this);
    }
    super.removalActions();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
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
