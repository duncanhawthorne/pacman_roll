import 'dart:core';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../../utils/helper.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'maze.dart';
import 'physics_ball.dart';

/// The [GameCharacter] is the generic object that is linked to a [PhysicsBall]
class GameCharacter extends SpriteAnimationGroupComponent<CharacterState>
    with
        //CollisionCallbacks,
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame> {
  GameCharacter({
    super.position,
    super.priority = 1,
  }) : super(size: Vector2.all(maze.spriteWidth()), anchor: Anchor.center);

  //final Vector2 startingPosition;
  late final PhysicsBall _underlyingBall = PhysicsBall(
      realCharacter: this,
      initialPosition: position,
      position: position); //to avoid null safety issues

  // Used to store the last position of the player, so that we later can
  // determine which direction that the player is moving.
  final Vector2 _lastPosition = Vector2.zero();
  final Vector2 _lastVelocity = Vector2.zero();
  bool connectedToBall = true;

  Vector2 getVelocity() {
    return _getUnderlyingBallVelocity();
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

  Vector2 _getUnderlyingBallPosition() {
    try {
      return _underlyingBall.position;
    } catch (e) {
      debug(["getUnderlyingBallPosition", e, _lastPosition]);
      return _lastPosition; //Vector2(10, 0);
    }
  }

  void _setUnderlyingBallPositionStill(Vector2 targetLoc) {
    _setUnderlyingBallPositionMoving(targetLoc);
    _setUnderlyingVelocity(Vector2(0, 0));
  }

  void _setUnderlyingBallPositionMoving(Vector2 targetLoc) {
    _underlyingBall.body.setTransform(targetLoc, angle);
    _lastPosition
        .setFrom(targetLoc); //else _lastVelocity calc produces nonsense
  }

  Vector2 _getUnderlyingBallVelocity() {
    try {
      return Vector2(_underlyingBall.body.linearVelocity.x,
          _underlyingBall.body.linearVelocity.y);
    } catch (e) {
      debug(["getUnderlyingBallVelocity", e, _lastVelocity]);
      return _lastVelocity;
    }
  }

  void _setUnderlyingVelocity(Vector2 vel) {
    _underlyingBall.body.linearVelocity.setFrom(vel);
    _lastVelocity.setFrom(vel);
  }

  void _moveUnderlyingBallThroughPipePortal() {
    assert(connectedToBall);
    if (position.x.abs() > maze.mazeWidth() / 2 * _portalMargin ||
        position.y.abs() > maze.mazeHeight() / 2 * _portalMargin) {
      _setUnderlyingBallPositionMoving(Vector2(
          _mod(position.x, maze.mazeWidth() * _portalMargin),
          _mod(position.y, maze.mazeHeight() * _portalMargin)));
    }
  }

  int _spinParity() {
    Vector2 vel = _getUnderlyingBallVelocity();
    if (vel.x.abs() > vel.y.abs()) {
      return (world.gravity.y > 0 ? 1 : -1) * (vel.x > 0 ? 1 : -1);
    } else {
      return (world.gravity.x > 0 ? -1 : 1) * (vel.y > 0 ? 1 : -1);
    }
  }

  double _getUpdatedAngle() {
    if (useForgePhysicsBallRotation) {
      try {
        return _underlyingBall.angle;
      } catch (e) {
        debug(["_getUpdatedAngle", e]);
        return angle;
      }
    } else {
      return angle +
          (position - _lastPosition).length / (size.x / 2) * _spinParity();
    }
  }

  void _oneFrameOfPhysics() {
    assert(connectedToBall);
    _moveUnderlyingBallThroughPipePortal(); //note never called for deadGhost
    position = _getUnderlyingBallPosition();
    angle = _getUpdatedAngle();
  }

  @override
  Future<void> onLoad() async {
    world.add(_underlyingBall);
    _lastPosition.setFrom(position);
    add(CircleHitbox(
      isSolid: true,
    )); //hitbox as large as possble
  }

  @override
  Future<void> onRemove() async {
    disconnectSpriteFromBall();
    world.remove(_underlyingBall);
    super.onRemove();
  }

  @override
  void update(double dt) {
    if (connectedToBall) {
      _oneFrameOfPhysics();
    }
    super.update(dt);
    _lastVelocity.setFrom((position - _lastPosition) / dt);
    _lastPosition.setFrom(position);
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
