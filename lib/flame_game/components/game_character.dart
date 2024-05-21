import 'package:flame/components.dart';

import '../endless_runner.dart';
import '../endless_world.dart';
import '../constants.dart';
import '../helper.dart';
import 'physics_ball.dart';
import 'dart:core';

import 'package:flame/collisions.dart';

/// The [GameCharacter] is the component that the physical player of the game is
/// controlling.
class GameCharacter extends SpriteAnimationGroupComponent<CharacterState>
    with
        //CollisionCallbacks,
        HasWorldReference<EndlessWorld>,
        HasGameReference<EndlessRunner> {
  GameCharacter({
    super.position,
  }) : super(
            size: Vector2.all(spriteWidth()),
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
    _lastPosition.setFrom(targetLoc); //Fixes bug. If body not initialised, which happens after setUnderlyingBallPosition, will revert to lastPosition so need that to be current position
    _lastVelocity.setFrom(Vector2(0,0));
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
      p(["getUnderlyingBallPosition", e, _lastPosition]);
      return _lastPosition; //Vector2(10, 0);
    }
  }

  void _setUnderlyingBallPosition(Vector2 targetLoc) {
    _underlyingBall.body.setTransform(targetLoc, angle);
    _underlyingBall.body.linearVelocity = Vector2(0, 0);
  }

  void setUnderlyingBallPosition(Vector2 targetLoc) {
    assert(current == CharacterState.deadGhost); //shouldn't be using this function otherwise
    _setUnderlyingBallPosition(targetLoc);
  }

  Vector2 _getUnderlyingBallVelocity() {
    try {
      return Vector2(_underlyingBall.body.linearVelocity.x,
          _underlyingBall.body.linearVelocity.y);
    } catch (e) {
      p(["getUnderlyingBallVelocity", e, _lastVelocity]);
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
    if (position.x > kRightPortalLocation.x) {
      Vector2 startVel = _getUnderlyingBallVelocity(); //before destroy ball
      _setUnderlyingBallPosition(kLeftPortalLocation);
      _lastPosition.setFrom(kLeftPortalLocation); //else _lastVelocity calc produces nonsense
      _setUnderlyingVelocity(startVel);
    } else if (position.x < kLeftPortalLocation.x) {
      Vector2 startVel = _getUnderlyingBallVelocity();
      _setUnderlyingBallPosition(kRightPortalLocation); //before destroy ball
      _lastPosition.setFrom(kRightPortalLocation); //else _lastVelocity calc produces nonsense
      _setUnderlyingVelocity(startVel);
    }
  }

  double _getUpdatedAngle() {
    double tmpAngle = 0;
    if (useForgePhysicsBallRotation) {
      try {
        tmpAngle = _underlyingBall.angle;
      } catch (e) {
        p(["_getUpdatedAngle", e]);
        tmpAngle = angle;
      }
    } else {
      tmpAngle = angle +
          (position - _lastPosition).length /
              (size.x / 2) *
              getRollSpinDirection(_getUnderlyingBallVelocity(), world.gravity);
    }
    return tmpAngle;
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
    _lastVelocity.setFrom(
        (position - _lastPosition) / dt);
    _lastPosition.setFrom(position);
  }
}

enum CharacterState { normal, scared, scaredIsh, eating, deadGhost, deadPacman }
