import 'dart:core';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../effects/remove_effects.dart';
import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'clones.dart';
import 'pacman.dart';
import 'physics_ball.dart';

final Paint highQualityPaint = Paint()
  ..filterQuality = FilterQuality.high
//..color = const Color.fromARGB(255, 255, 255, 255)
  ..isAntiAlias = true;

const bool portalClones = true;
final kVector2Zero = Vector2.zero();

/// The [GameCharacter] is the generic object that is linked to a [PhysicsBall]
class GameCharacter extends SpriteAnimationGroupComponent<CharacterState>
    with
        //CollisionCallbacks,
        IgnoreEvents,
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame> {
  GameCharacter({super.position, super.priority = 1, this.original})
      : super(
            size: maze.spriteSize,
            paint: highQualityPaint,
            anchor: Anchor.center);

  late final PhysicsBall _ball = PhysicsBall(position: position);

  bool connectedToBall = true;

  double get speed => _ball.speed;

  int get _spinParity =>
      _ball.body.linearVelocity.x.abs() > _ball.body.linearVelocity.y.abs()
          ? (world.gravity.y > 0 ? 1 : -1) *
              (_ball.body.linearVelocity.x > 0 ? 1 : -1)
          : (world.gravity.x > 0 ? -1 : 1) *
              (_ball.body.linearVelocity.y > 0 ? 1 : -1);

  bool get typical =>
      connectedToBall &&
      current != CharacterState.dead &&
      current != CharacterState.spawning;

  GameCharacter? clone;
  GameCharacter? original;

  void bringBallToSprite() {
    if (isMounted && !isRemoving) {
      // must test isMounted as bringBallToSprite typically runs after a delay
      // and could have reset to remove the ball in the meantime
      setPositionStill(position);
    }
  }

  void setPositionStill(Vector2 targetLoc) {
    _ball.position = targetLoc;
    _ball.velocity = kVector2Zero;
    position.setFrom(targetLoc);
    _connectToBall();
  }

  void disconnectFromBall({spawning = false}) {
    if (!spawning) {
      /// if body not yet initialised, this will crash
      _ball.setStatic();
    }
    connectedToBall = false;
  }

  void _connectToBall() {
    connectedToBall = true;
    _ball.setDynamic();
  }

  void _oneFrameOfPhysics(double dt) {
    if (connectedToBall) {
      position.setFrom(_ball.position);
      angle += speed * dt / (size.x / 2) * _spinParity;
    }
  }

  @override
  void removeFromParent() {
    disconnectFromBall(); //sync
    removeEffects(this); //sync and async
    super.removeFromParent(); //async
  }

  @override
  Future<void> onLoad() async {
    parent!.add(_ball); //should be added to static parent but risks going stray
    add(CircleHitbox(
      isSolid: true,
      collisionType:
          this is Pacman ? CollisionType.active : CollisionType.passive,
    )); //hitbox as large as possible
  }

  @override
  Future<void> onRemove() async {
    //removeEffects(this); //dont run this, runs async code which will execute after the item has already been removed and cause a crash
    disconnectFromBall(); //sync but within async function
    _ball.removeFromParent();
    clone?.removeFromParent();
    super.onRemove();
  }

  void _addRemoveClone(GameCharacter? clone) {
    if (portalClones) {
      if (clone != null) {
        //i.e. no cascade of clones
        assert(clone is PacmanClone || clone is GhostClone);
        assert(this is! PacmanClone && this is! GhostClone);
        if (position.x.abs() > maze.mazeWidth / 2 - maze.spriteWidth / 2) {
          if (!clone.isMounted) {
            parent!.add(clone);
          }
        } else {
          if (clone.isMounted) {
            parent!.remove(clone);
          }
        }
      }
    }
  }

  @override
  void update(double dt) {
    //note, this function is also run for clones
    _oneFrameOfPhysics(dt);
    _addRemoveClone(clone);
    super.update(dt);
  }
}

enum CharacterState { normal, scared, scaredIsh, eating, dead, spawning }
