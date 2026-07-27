import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../../utils/constants.dart';
import '../custom_game.dart';
import '../effects/move_to_effect.dart';
import '../effects/null_effect.dart';
import '../effects/remove_effects.dart';
import '../icons/pacman_sprites.dart';
import '../maze/maze.dart';
import 'clones.dart';
import 'game_character.dart';
import 'ghost.dart';
import 'pellet.dart';
import 'sprite_character.dart';
import 'super_pellet.dart';
import 'wall_dynamic.dart';
import 'wall_dynamic_layer.dart';

const int _kPacmanDeadResetTimeMillis = 1550;
const int _kPacmanHalfEatingResetTimeMillis = 180;
const bool multipleSpawningPacmans = false;
const bool _freezeGhostsOnKillPacman = false;

/// The [GameCharacter] is the component that the physical player of the game is
/// controlling.
class Pacman extends GameCharacter with CollisionCallbacks {
  Pacman({required super.position, super.original})
    : super(velocity: Vector2.zero(), radius: maze.dimensions.spriteWidth / 2);

  final Vector2 _screenSizeLast = Vector2.zero();

  /// Timer used to control the mouth-closing animation duration when eating.
  final Timer _eatTimer = Timer(_kPacmanHalfEatingResetTimeMillis * 2 / 1000);

  @override
  /// Loads or retrieves animations for Pacman (Normal, Eating, Dying, Spawning).
  Future<Map<CharacterState, SpriteAnimation>> getAnimations([
    int size = 1,
  ]) async {
    final List<List<Sprite>> sprites =
        await Future.wait<List<Sprite>>(<Future<List<Sprite>>>[
          pacmanSprites.pacmanNormalSprites(size),
          pacmanSprites.pacmanEatingSprites(size),
          pacmanSprites.pacmanDyingSprites(size),
          pacmanSprites.pacmanBirthingSprites(size),
        ]);

    return <CharacterState, SpriteAnimation>{
      CharacterState.normal: SpriteAnimation.spriteList(
        sprites[0],
        stepTime: double.infinity,
      ),
      CharacterState.eating: SpriteAnimation.spriteList(
        sprites[1],
        stepTime:
            _kPacmanHalfEatingResetTimeMillis /
            1000 /
            pacmanEatingHalfIncrements,
        loop: false,
      ),
      CharacterState.dead: SpriteAnimation.spriteList(
        sprites[2],
        stepTime:
            kPacmanDeadResetTimeAnimationMillis / 1000 / pacmanDeadIncrements,
        loop: false,
      ),
      CharacterState.spawning: SpriteAnimation.spriteList(
        sprites[3],
        stepTime: kResetPositionTimeMillis / 1000 / pacmanDeadIncrements,
        loop: false,
      ),
    };
  }

  /// Triggers the eating animation and plays the appropriate sound effect.
  void _eat({required bool isPellet}) {
    assert(typical);
    if (current == CharacterState.normal) {
      current = CharacterState.eating;
      _eatTimer.start();
      if (isPellet) {
        //only play waka if not recently played waka
        game.audioController.play(SfxType.waka);
      }
    }
    if (!isPellet) {
      //play eatGhost irrespective of current state
      game.audioController.play(SfxType.eatGhost);
    }
    //if in eating state, just let that sequence complete normally
  }

  /// Handles collision with other components like pellets and ghosts.
  void onCollideWith(PositionComponent other) {
    if (isClone) {
      (original! as Pacman).onCollideWith(other);
      return;
    }

    if (!typical) return;

    if (other is Pellet) {
      _onCollideWithPellet(other);
    } else if (other is Ghost) {
      final Ghost ghost = other is GhostClone
          ? (other.original! as Ghost)
          : other;
      _onCollideWithGhost(ghost);
    } else if (enableMovingWalls &&
        movingWallsDamage &&
        other is MovingWallWrapper) {
      _dieFromGhost();
    }
  }

  void _onCollideWithPellet(Pellet pellet) {
    assert(typical);
    // can simultaneously eat pellet and die to ghost
    // so don't want to do this if just died
    pellet.removeFromParent(); //do this first, for checks based on game over
    if (pellet is SuperPellet) {
      world.ghosts.scareGhosts();
    }
    _eat(isPellet: true);
  }

  void _onCollideWithGhost(Ghost ghost) {
    assert(typical);
    if (ghost.typical) {
      if (ghost.current == CharacterState.scared ||
          ghost.current == CharacterState.scaredIsh) {
        _eatGhost(ghost);
      } else {
        _dieFromGhost();
      }
    }
  }

  /// Initiates the ghost-eating sequence, awarding points and resetting the ghost.
  void _eatGhost(Ghost ghost) {
    assert(typical);
    assert(ghost.typical);
    _eat(isPellet: false);
    ghost.setDead();
    if (multipleSpawningPacmans) {
      world.pacmans.add(Pacman(position: position + Vector2.random() / 100));
    }
  }

  /// Handles Pacman's death sequence when colliding with a ghost.
  void _dieFromGhost() {
    if (game.playState == PlayState.flourish) {
      // avoid race condition
      // already doing a level reset flourish from somewhere else
      return;
    }
    if (!typical) return;
    if (!game.session.isWonOrLost) {
      current = CharacterState.dead;
      setPhysicsState(PhysicsState.none);
      game.audioController.play(SfxType.pacmanDeath);
      if (_freezeGhostsOnKillPacman) {
        world.ghosts.disconnectGhostsFromBalls();
      }
      world.pacmans.pacmanDyingNotifier.value++;
      if (world.pacmans.pacmanDeathIsFinalPacman) {
        game.playState = PlayState.flourish;
        game.lifecycle.stopRegularItems();
      }
      add(
        NullEffect(
          _kPacmanDeadResetTimeMillis,
          onComplete: _dieFromGhostActionAfterDeathAnimation,
        ),
      );
    }
  }

  /// Action performed after the death animation finishes, such as reducing lives or resetting the level.
  void _dieFromGhostActionAfterDeathAnimation() {
    if (current == CharacterState.dead && !game.session.isWonOrLost) {
      if (world.pacmans.pacmanDeathIsFinalPacman) {
        if (game.playState == PlayState.flourish) {
          /// must test [PlayState.flourish]
          /// as could have been removed by reset during delay
          game.session.numberOfDeathsNotifier.value++; //score counting deaths
          world.deathReset.resetAfterPacmanDeath(this);
        }
      } else {
        assert(multipleSpawningPacmans);
        //possible bug here if two pacmans are removed in quick succession
        removeFromParent();
      }
    }
  }

  /// Resets Pacman's position with a sliding animation after death.
  void resetSlideAfterDeath() {
    removeEffects(this);
    setPositionStillStatic(maze.dimensions.pacmanStart);
    angle = 0;
    current = CharacterState.spawning;
  }

  /// Instantly resets Pacman to the starting position without animation.
  void resetInstantAfterDeath() {
    removeEffects(this);
    setPositionStillActive(maze.dimensions.pacmanStart);
    angle = 0;
    current = CharacterState.normal;
  }

  /// Manages the state transitions (e.g., from Eating back to Normal).
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
      final int newSize = 2 * maze.dimensions.spriteWidthOnScreen(size);
      if (newSize > 0) {
        _screenSizeLast.setFrom(size);
        animations = await getAnimations(newSize);
      }
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
    assert(isMounted && other.isMounted);
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
