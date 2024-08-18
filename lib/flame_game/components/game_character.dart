import 'dart:core';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

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

/// The [GameCharacter] is the generic object that is linked to a [PhysicsBall]
class GameCharacter extends SpriteAnimationGroupComponent<CharacterState>
    with
        //CollisionCallbacks,
        IgnoreEvents,
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame> {
  GameCharacter({super.position, super.priority = 1, this.original})
      : super(
            size: Vector2.all(maze.spriteWidth),
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
    setPositionStill(position);
  }

  void setPositionStill(Vector2 targetLoc) {
    _ball.position = targetLoc;
    _ball.velocity = Vector2(0, 0);
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
    //removeWhere((item) => item is Effect); //dont run this, runs async code which will execute after the item has already been removed and cause a crash
    disconnectFromBall(); //sync but within async function
    _ball.removeFromParent();
    if (clone != null && clone!.isMounted) {
      parent!.remove(clone!);
    }
    super.onRemove();
  }

  void _addRemoveClone(GameCharacter? clone) {
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

  @override
  void update(double dt) {
    _oneFrameOfPhysics(dt);
    _addRemoveClone(clone);
    super.update(dt);
  }
}

enum CharacterState { normal, scared, scaredIsh, eating, dead, spawning }
