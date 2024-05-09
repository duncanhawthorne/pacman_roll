import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../endless_runner.dart';
import '../endless_world.dart';
import '../constants.dart';
import '../helper.dart';
import 'physics_ball.dart';
import 'dart:core';

/// The [GameCharacter] is the component that the physical player of the game is
/// controlling.
class GameCharacter extends SpriteAnimationGroupComponent<CharacterState>
    with
        CollisionCallbacks,
        HasWorldReference<EndlessWorld>,
        HasGameReference<EndlessRunner> {
  GameCharacter({
    required this.startingPosition,
    super.position,
  }) : super(
            size: Vector2.all(getSingleSquareWidth()),
            anchor: Anchor.center,
            priority: 1);

  int ghostNumberForSprite = 1;

  final Vector2 startingPosition;
  late PhysicsBall underlyingBallReal = PhysicsBall(
      realCharacter: this,
      initialPosition: startingPosition); //to avoid null safety issues

  double underlyingAngle = 0;
  // Used to store the last position of the player, so that we later can
  // determine which direction that the player is moving.
  // ignore: prefer_final_fields
  Vector2 _lastUnderlyingPosition = Vector2.zero();
  // ignore: prefer_final_fields
  Vector2 _lastUnderlyingVelocity = Vector2.zero();

  PhysicsBall createUnderlyingBall(Vector2 targetPosition) {
    PhysicsBall underlyingBallRealTmp =
        PhysicsBall(realCharacter: this, initialPosition: targetPosition);
    //underlyingBallRealTmp.realCharacter =
    //    this;
    //underlyingBallRealTmp.createBody();
    //underlyingBallRealTmp.bodyDef!.position = startPosition;
    return underlyingBallRealTmp;
  }

  Vector2 getUnderlyingBallPosition() {
    try {
      return underlyingBallReal.position;
    } catch (e) {
      //FIXME body not initialised. Shouldn't need this, hid error
      //p(["getUnderlyingBallPosition", e]);
      return _lastUnderlyingPosition; //Vector2(10, 0);
    }
  }

  void setUnderlyingBallPosition(Vector2 targetLoc) {
    underlyingBallReal
        .removeFromParent(); //note possible risk that may try to remove a ball that isn't in the world
    underlyingBallReal = createUnderlyingBall(targetLoc);
    world.add(underlyingBallReal);
  }

  Vector2 getUnderlyingBallVelocity() {
    try {
      return Vector2(underlyingBallReal.body.linearVelocity.x,
          underlyingBallReal.body.linearVelocity.y);
    } catch (e) {
      //FIXME body not initialised. Shouldn't need this, hid error
      //p(["getUnderlyingBallVelocity", e]);
      return _lastUnderlyingVelocity;
    }
  }

  void setUnderlyingVelocity(Vector2 vel) {
    try {
      underlyingBallReal.body.linearVelocity = vel;
    } catch (e) {
      Future.delayed(const Duration(seconds: 0), () {
        //FIXME body not initialised. Shouldn't need this, hid error
        underlyingBallReal.body.linearVelocity = vel;
      });
    }
  }

  void moveUnderlyingBallThroughPipe() {
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

  void updateUnderlyingAngle() {
    if (useForgePhysicsBallRotation) {
      try {
        underlyingAngle = underlyingBallReal.angle;
      } catch (e) {
        //FIXME body not initialised. Shouldn't need this, hid error
      }
    } else {
      underlyingAngle = underlyingAngle +
          (getUnderlyingBallPosition() - _lastUnderlyingPosition).length /
              (size.x / 2) *
              getRollSpinDirection(
                  world, getUnderlyingBallVelocity(), world.gravity);
    }
  }

  double getUpdatedAngle() {
    updateUnderlyingAngle();
    return underlyingAngle +
        (actuallyMoveSpritesToScreenPos ? world.worldAngle : 0);
  }

  void oneFrameOfPhysics() {
    moveUnderlyingBallThroughPipe();
    position = world.screenPos(getUnderlyingBallPosition());
    angle = getUpdatedAngle();
  }

  @override
  Future<void> onLoad() async {
    setUnderlyingBallPosition(
        startingPosition); //FIXME shouldn't be necessary, but avoids one frame starting glitch
    _lastUnderlyingPosition.setFrom(getUnderlyingBallPosition());
  }

  @override
  void update(double dt) {
    super.update(dt);

    _lastUnderlyingPosition.setFrom(getUnderlyingBallPosition());
    _lastUnderlyingVelocity.setFrom(getUnderlyingBallVelocity());
  }
}

enum CharacterState { normal, scared, scaredIsh, eating, deadGhost, deadPacman }
