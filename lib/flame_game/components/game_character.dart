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
            size: Vector2.all(getSingleSquareWidth()),
            anchor: Anchor.center,
            priority: 1);

  //final Vector2 startingPosition;
  late PhysicsBall _underlyingBall = PhysicsBall(
      realCharacter: this,
      initialPosition: position,
      position: position); //to avoid null safety issues

  // Used to store the last position of the player, so that we later can
  // determine which direction that the player is moving.
  // ignore: prefer_final_fields
  Vector2 _lastUnderlyingBallPosition = Vector2.zero();
  // ignore: prefer_final_fields
  Vector2 _lastUnderlyingBallVelocity = Vector2.zero();

  PhysicsBall createUnderlyingBall(Vector2 targetPosition) {
    PhysicsBall underlyingBallRealTmp =
        PhysicsBall(realCharacter: this, initialPosition: targetPosition);
    //underlyingBallRealTmp.realCharacter =
    //    this;
    //underlyingBallRealTmp.createBody();
    //underlyingBallRealTmp.bodyDef!.position = startPosition;
    return underlyingBallRealTmp;
  }

  void removeUnderlyingBall() {
    world.remove(_underlyingBall);
  }

  Vector2 getUnderlyingBallPosition() {
    try {
      return _underlyingBall.position;
    } catch (e) {
      //FIXME body not initialised. Shouldn't need this, hid error
      //p(["getUnderlyingBallPosition", e, _lastUnderlyingBallPosition]);
      return _lastUnderlyingBallPosition; //Vector2(10, 0);
    }
  }

  void setUnderlyingBallPosition(Vector2 targetLoc) {
    _underlyingBall
        .removeFromParent(); //note possible risk that may try to remove a ball that isn't in the world
    _underlyingBall = createUnderlyingBall(targetLoc);
    world.add(_underlyingBall);
  }

  Vector2 getUnderlyingBallVelocity() {
    try {
      return Vector2(_underlyingBall.body.linearVelocity.x,
          _underlyingBall.body.linearVelocity.y);
    } catch (e) {
      //FIXME body not initialised. Shouldn't need this, hid error
      //p(["getUnderlyingBallVelocity", e]);
      return _lastUnderlyingBallVelocity;
    }
  }

  void setUnderlyingVelocity(Vector2 vel) {
    try {
      _underlyingBall.body.linearVelocity = vel;
    } catch (e) {
      Future.delayed(const Duration(seconds: 0), () {
        //FIXME body not initialised. Shouldn't need this, hid error
        _underlyingBall.body.linearVelocity = vel;
      });
    }
  }

  void moveUnderlyingBallThroughPipePortal() {
    if (!debugMode) {
      if (getUnderlyingBallPosition().x > 10 * getSingleSquareWidth()) {
        setUnderlyingBallPosition(kLeftPortalLocation);
        setUnderlyingVelocity(getUnderlyingBallVelocity());
      } else if (getUnderlyingBallPosition().x < -10 * getSingleSquareWidth()) {
        setUnderlyingBallPosition(kRightPortalLocation);
        setUnderlyingVelocity(getUnderlyingBallVelocity());
      }
    }
  }

  double getUpdatedAngle() {
    double tmpAngle = 0;
    if (useForgePhysicsBallRotation) {
      try {
        tmpAngle = _underlyingBall.angle;
      } catch (e) {
        //FIXME body not initialised. Shouldn't need this, hid error
        tmpAngle = angle;
      }
    } else {
      //p([(getUnderlyingBallPosition() - _lastUnderlyingBallPosition).length]);
      tmpAngle = angle +
          (getUnderlyingBallPosition() - _lastUnderlyingBallPosition).length /
              (size.x / 2) *
              getRollSpinDirection(getUnderlyingBallVelocity(), world.gravity);
    }
    return tmpAngle;
  }

  void oneFrameOfPhysics() {
    moveUnderlyingBallThroughPipePortal();
    position = getUnderlyingBallPosition();
    angle = getUpdatedAngle();
  }

  @override
  Future<void> onLoad() async {
    setUnderlyingBallPosition(
        position); //FIXME shouldn't be necessary, but avoids one frame starting glitch
    _lastUnderlyingBallPosition.setFrom(position);
    // When adding a CircleHitbox without any arguments it automatically
    // fills up the size of the component as much as it can without overflowing
    // it.
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lastUnderlyingBallPosition.setFrom(getUnderlyingBallPosition());
    _lastUnderlyingBallVelocity.setFrom(getUnderlyingBallVelocity());
  }
}

enum CharacterState { normal, scared, scaredIsh, eating, deadGhost, deadPacman }
