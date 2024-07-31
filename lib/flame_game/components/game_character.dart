import 'dart:core';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'pacman.dart';
import 'physics_ball.dart';

/// The [GameCharacter] is the generic object that is linked to a [PhysicsBall]
class GameCharacter extends SpriteAnimationGroupComponent<CharacterState>
    with
        //CollisionCallbacks,
        IgnoreEvents,
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame> {
  GameCharacter({
    super.position,
    super.priority = 1,
  }) : super(
            size: Vector2.all(maze.spriteWidth()),
            paint: Paint()
              ..filterQuality = FilterQuality.high
              //..color = const Color.fromARGB(255, 255, 255, 255)
              ..isAntiAlias = true,
            anchor: Anchor.center);

  late final PhysicsBall _underlyingBall = PhysicsBall(
      realCharacter: this,
      initialPosition: position,
      position: position); //to avoid null safety issues

  bool connectedToBall = true;

  double getSpeed() {
    return _underlyingBall.body.linearVelocity.length;
  }

  void setPositionStill(Vector2 targetLoc) {
    _setUnderlyingBallPositionStill(targetLoc);
    position.setFrom(targetLoc);
    _setUnderlyingBallDynamic();
  }

  void disconnectSpriteFromBall() {
    _setUnderlyingBallStatic();
    connectedToBall = false;
  }

  void disconnectFromPhysics() {
    _setUnderlyingBallStatic();
  }

  void _setUnderlyingBallDynamic() {
    _underlyingBall.body.setType(BodyType.dynamic);
    _underlyingBall.body.setActive(true);
    connectedToBall = true;
  }

  void _setUnderlyingBallStatic() {
    _underlyingBall.body.setType(BodyType.static);
    _underlyingBall.body.setActive(false);
  }

  void _setUnderlyingBallPositionStill(Vector2 targetLoc) {
    _setUnderlyingBallPositionMoving(targetLoc);
    _setUnderlyingVelocity(Vector2(0, 0));
  }

  void _setUnderlyingBallPositionMoving(Vector2 targetLoc) {
    _underlyingBall.body.setTransform(targetLoc, angle);
  }

  void _setUnderlyingVelocity(Vector2 vel) {
    _underlyingBall.body.linearVelocity.setFrom(vel);
  }

  void _moveUnderlyingBallThroughPipePortal() {
    assert(connectedToBall);
    if (position.x.abs() > maze.mazeWidth / 2 * _portalMargin ||
        position.y.abs() > maze.mazeHeight / 2 * _portalMargin) {
      _setUnderlyingBallPositionMoving(Vector2(
          _mod(position.x, maze.mazeWidth * _portalMargin),
          _mod(position.y, maze.mazeHeight * _portalMargin)));
    }
  }

  int _spinParity() {
    return _underlyingBall.body.linearVelocity.x.abs() >
            _underlyingBall.body.linearVelocity.y.abs()
        ? (world.gravity.y > 0 ? 1 : -1) *
            (_underlyingBall.body.linearVelocity.x > 0 ? 1 : -1)
        : (world.gravity.x > 0 ? -1 : 1) *
            (_underlyingBall.body.linearVelocity.y > 0 ? 1 : -1);
  }

  void _oneFrameOfPhysics(double dt) {
    if (connectedToBall) {
      _moveUnderlyingBallThroughPipePortal(); //note never called for deadGhost
      position.setFrom(_underlyingBall.position);
      angle += getSpeed() * dt / (size.x / 2) * _spinParity();
    }
  }

  @override
  Future<void> onLoad() async {
    add(_underlyingBall);
    add(CircleHitbox(
      isSolid: true,
      collisionType:
          this is Pacman ? CollisionType.active : CollisionType.passive,
    )); //hitbox as large as possible
  }

  @override
  Future<void> onRemove() async {
    disconnectSpriteFromBall();
    _underlyingBall.removeFromParent();
    super.onRemove();
  }

  @override
  void update(double dt) {
    _oneFrameOfPhysics(dt);
    super.update(dt);
  }
}

enum CharacterState {
  normal,
  scared,
  scaredIsh,
  eating,
  deadGhost,
  deadPacman,
  birthing
}

const _portalMargin = 0.97;

double _mod(double position, double mod) {
  if (position > mod / 2) {
    return position - mod;
  } else if (position < -mod / 2) {
    return position + mod;
  } else {
    return position;
  }
}
