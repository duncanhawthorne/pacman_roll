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
  late final PhysicsBall _underlyingBall = PhysicsBall(
      realCharacter: this,
      initialPosition: position,
      position: position); //to avoid null safety issues

  // Used to store the last position of the player, so that we later can
  // determine which direction that the player is moving.
  final Vector2 _lastPosition = Vector2.zero();
  final Vector2 _lastVelocity = Vector2.zero();

  /*
  PhysicsBall createUnderlyingBall(Vector2 targetPosition) {
    return PhysicsBall(realCharacter: this, initialPosition: targetPosition);
    //underlyingBallRealTmp.realCharacter =
    //    this;
    //underlyingBallRealTmp.createBody();
    //underlyingBallRealTmp.bodyDef!.position = startPosition;
    //return underlyingBallRealTmp;
  }


   */

  /*
  void removeUnderlyingBallFromWorld() {
    world.remove(_underlyingBall);
  }

   */

  /*
  void removeSelfFromWorld() {
    //removeUnderlyingBallFromWorld();
    world.remove(_underlyingBall);
    world.remove(this);
  }

   */

/*
  void addUnderlyingBallToWorld() {
    world.add(_underlyingBall);
  }

 */

  Vector2 getVelocity() {
    return _getUnderlyingBallVelocity();
  }

  void setPosition(Vector2 targetLoc) {
    setUnderlyingBallPosition(targetLoc);
    position.setFrom(targetLoc);
  }

  Vector2 _getUnderlyingBallPosition() {
    try {
      return _underlyingBall.position;
    } catch (e) {
      //FIXME body not initialised. Shouldn't need this, hid error
      p(["getUnderlyingBallPosition", e, _lastPosition]);
      return _lastPosition; //Vector2(10, 0);
    }
  }

  void setUnderlyingBallPosition(Vector2 targetLoc) {
    _underlyingBall.body.setTransform(targetLoc, angle);
    _underlyingBall.body.linearVelocity = Vector2(0, 0);
    //_underlyingBall.body.setAwake(true);
    /*
    _underlyingBall
        .removeFromParent(); //note possible risk that may try to remove a ball that isn't in the world
    //removeUnderlyingBallFromWorld();
    _underlyingBall = createUnderlyingBall(targetLoc);
    //world.add(_underlyingBall);
    addUnderlyingBallToWorld()
     */
  }

  Vector2 _getUnderlyingBallVelocity() {
    try {
      return Vector2(_underlyingBall.body.linearVelocity.x,
          _underlyingBall.body.linearVelocity.y);
    } catch (e) {
      //FIXME body not initialised. Shouldn't need this, hid error
      p(["getUnderlyingBallVelocity", e, _lastVelocity]);
      return _lastVelocity;
    }
  }

  void _setUnderlyingVelocity(Vector2 vel) {
    Future.delayed(const Duration(seconds: 0), () {
      _underlyingBall.body.linearVelocity = vel;
    });
    /*
    try {
      _underlyingBall.body.linearVelocity = vel;
    } catch (e) {
      //FIXME body not initialised. Shouldn't need this, hid error
      p(["setUnderlyingVelocity", e, vel]);
      Future.delayed(const Duration(seconds: 0), () {
        _underlyingBall.body.linearVelocity = vel;
      });
    }
     */
  }

  void _moveUnderlyingBallThroughPipePortal() {
    if (position.x > 10 * getSingleSquareWidth()) {
      Vector2 startVel = _getUnderlyingBallVelocity(); //before destroy ball
      setUnderlyingBallPosition(kLeftPortalLocation);
      _setUnderlyingVelocity(startVel);
    } else if (position.x < -10 * getSingleSquareWidth()) {
      Vector2 startVel = _getUnderlyingBallVelocity();
      setUnderlyingBallPosition(kRightPortalLocation); //before destroy ball
      _setUnderlyingVelocity(startVel);
    }
  }

  double _getUpdatedAngle() {
    double tmpAngle = 0;
    if (useForgePhysicsBallRotation) {
      try {
        tmpAngle = _underlyingBall.angle;
      } catch (e) {
        //FIXME body not initialised. Shouldn't need this, hid error
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
    position = _getUnderlyingBallPosition();
    angle = _getUpdatedAngle();
    _moveUnderlyingBallThroughPipePortal();
  }

  @override
  Future<void> onLoad() async {
    world.add(_underlyingBall);
    //addUnderlyingBallToWorld();
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
        (position - _lastPosition) / dt); //FIXME except ball through portal
    _lastPosition.setFrom(position);
  }
}

enum CharacterState { normal, scared, scaredIsh, eating, deadGhost, deadPacman }
