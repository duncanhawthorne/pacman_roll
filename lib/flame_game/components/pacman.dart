import 'dart:core';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../icons/pacman_sprites.dart';
import '../maze.dart';
import 'game_character.dart';
import 'ghost.dart';
import 'pacman_layer.dart';
import 'pellet.dart';
import 'super_pellet.dart';

const int _kPacmanDeadResetTimeMillis = 1700;
const int kPacmanDeadResetTimeAnimationMillis = 1250;
const int _kPacmanHalfEatingResetTimeMillis = 180;

/// The [GameCharacter] is the component that the physical player of the game is
/// controlling.
class Pacman extends GameCharacter with CollisionCallbacks {
  Pacman({
    required super.position,
  }) : super(priority: 2);

  int _pacmanStartEatingTimeLatest = 0; //a long time ago
  int _pacmanDeadTimeLatest = 0; //a long time ago
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
      CharacterState.dead: SpriteAnimation.spriteList(
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

  void _eat({required isPellet}) {
    if (current != CharacterState.dead) {
      if (current == CharacterState.normal) {
        current = CharacterState.eating;
        _pacmanStartEatingTimeLatest = game.now;
        if (isPellet) {
          world.play(SfxType.waka);
        } else {
          world.play(SfxType.eatGhost);
        }
      }
    }
  }

  void _onCollideWith(PositionComponent other) {
    if (current != CharacterState.dead) {
      if (other is Pellet) {
        _onCollideWithPellet(other);
      } else if (other is Ghost) {
        //If turn on collision callbacks in physicsBall this would be belt and braces. Right now not
        _onCollideWithGhost(other);
      }
    }
  }

  void _onCollideWithPellet(Pellet pellet) {
    if (current != CharacterState.dead) {
      // can simultaneously eat pellet and die to ghost so don't want to do this if just died
      pellet.removeFromParent(); //do this first, for checks based on game over
      if (pellet is SuperPellet) {
        world.ghosts.scareGhosts();
      }
      _eat(isPellet: true);
    }
  }

  void _onCollideWithGhost(Ghost ghost) {
    if (ghost.current == CharacterState.dead ||
        current == CharacterState.dead ||
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
    if (current != CharacterState.dead) {
      //pacman visuals
      _eat(isPellet: false);

      //ghost impact
      ghost.setDead();

      //other impact
      if (multipleSpawningPacmans) {
        world.pacmans.add(Pacman(position: position + Vector2.random() / 100));
      }
    }
  }

  static const bool _freezeGhostsOnKillPacman = false;
  void _dieFromGhost() {
    if (current != CharacterState.dead &&
        world.pellets.pelletsRemainingNotifier.value != 0) {
      world.play(SfxType.pacmanDeath);
      current = CharacterState.dead;
      disconnectFromBall();
      if (_freezeGhostsOnKillPacman) {
        world.ghosts.disconnectGhostsFromBalls();
      }
      world.pacmans.pacmanDyingNotifier.value++;

      if (world.pacmans.pacmanList.length == 1 ||
          world.pacmans.numberAlivePacman() == 0) {
        _pacmanDeadTimeLatest = game.now;
        world.doingLevelResetFlourish.value = true;
        game.stopwatch.stop();
        world.ghosts.cancelMultiGhostAdderTimer();
      }
    }
  }

  void _dieFromGhostActionAfterDeathAnimation() {
    if (world.pacmans.pacmanList.length == 1 ||
        world.pacmans.numberAlivePacman() == 0) {
      world.pacmans.numberOfDeathsNotifier.value++; //score counting deaths
      world.resetAfterPacmanDeath(this);
    } else {
      assert(multipleSpawningPacmans);
      removeFromParent();
    }
  }

  void resetSlideAfterDeath() {
    setPositionStill(maze.pacmanStart);
    disconnectFromBall();
    angle = 0;
    current = CharacterState.birthing;
  }

  void resetInstantAfterDeath() {
    setPositionStill(maze.pacmanStart);
    angle = 0;
    current = CharacterState.normal;
  }

  void _pacmanDeadEatingNormalSequence() {
    if (current == CharacterState.dead && !world.gameWonOrLost) {
      if (game.now - _pacmanDeadTimeLatest > _kPacmanDeadResetTimeMillis) {
        _dieFromGhostActionAfterDeathAnimation();
        assert(current != CharacterState.dead || world.gameWonOrLost);
      }
    }
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
    if (size.x != _screenSizeLast.x || size.y != _screenSizeLast.y) {
      _screenSizeLast.setFrom(size);
      animations = await _getAnimations(2 * maze.spriteWidthOnScreen(size));
    }
    super.onGameResize(size);
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
    _pacmanDeadEatingNormalSequence();
    super.update(dt);
  }
}
