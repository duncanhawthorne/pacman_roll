import 'dart:core';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

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
  }) : super(
            size: Vector2.all(maze.spriteWidth()),
            anchor: Anchor.center,
            priority: 1);

  //final Vector2 startingPosition;
  late final PhysicsBall _underlyingBall = PhysicsBall(
      realCharacter: this,
      initialPosition: position,
      position: position); //to avoid null safety issues

  // Used to store the last position of the player, so that we later can
  // determine which direction that the player is moving.
  final Vector2 _lastPosition = Vector2.zero();
  final Vector2 _lastVelocity = Vector2.zero();

  Vector2 getVelocity() {
    return _getUnderlyingBallVelocity();
  }

  void setPosition(Vector2 targetLoc) {
    _setUnderlyingBallPosition(targetLoc);
    position.setFrom(targetLoc);
    _lastPosition.setFrom(
        targetLoc); //Fixes bug. If body not initialised, which happens after setUnderlyingBallPosition, will revert to lastPosition so need that to be current position
    _lastVelocity.setFrom(Vector2(0, 0));
  }

  /*
  void setUnderlyingBallDynamic() {
    _underlyingBall.body.setType(BodyType.dynamic);
  }

  void setUnderlyingBallStatic() {
    _underlyingBall.body.setType(BodyType.static);
  }
   */

  Vector2 _getUnderlyingBallPosition() {
    try {
      return _underlyingBall.position;
    } catch (e) {
      debug(["getUnderlyingBallPosition", e, _lastPosition]);
      return _lastPosition; //Vector2(10, 0);
    }
  }

  void _setUnderlyingBallPosition(Vector2 targetLoc) {
    _underlyingBall.body.setTransform(targetLoc, angle);
    _underlyingBall.body.linearVelocity = Vector2(0, 0);
  }

  void setUnderlyingBallPosition(Vector2 targetLoc) {
    assert(current ==
        CharacterState.deadGhost); //shouldn't be using this function otherwise
    _setUnderlyingBallPosition(targetLoc);
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
    Future.delayed(const Duration(seconds: 0), () {
      _underlyingBall.body.linearVelocity = vel;
    });
  }

  void _moveUnderlyingBallThroughPipePortal() {
    assert(current != CharacterState.deadGhost); //as physics doesn't apply
    if (position.x > maze.rightPortal.x) {
      Vector2 startVel = _getUnderlyingBallVelocity(); //before destroy ball
      _setUnderlyingBallPosition(maze.leftPortal);
      _lastPosition
          .setFrom(maze.leftPortal); //else _lastVelocity calc produces nonsense
      _setUnderlyingVelocity(startVel);
    } else if (position.x < maze.leftPortal.x) {
      Vector2 startVel = _getUnderlyingBallVelocity();
      _setUnderlyingBallPosition(maze.rightPortal); //before destroy ball
      _lastPosition.setFrom(
          maze.rightPortal); //else _lastVelocity calc produces nonsense
      _setUnderlyingVelocity(startVel);
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

  void oneFrameOfPhysics() {
    assert(current != CharacterState.deadGhost);
    if (current != CharacterState.deadGhost) {
      //if statement shouldn't be necessary, but asserts aren't enforced in production
      position = _getUnderlyingBallPosition();
      angle = _getUpdatedAngle();
      _moveUnderlyingBallThroughPipePortal(); //note never called for deadGhost
    }
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
    world.remove(_underlyingBall);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lastVelocity.setFrom((position - _lastPosition) / dt);
    _lastPosition.setFrom(position);
  }
}

enum CharacterState { normal, scared, scaredIsh, eating, deadGhost, deadPacman }
