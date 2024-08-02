import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../maze.dart';
import 'game_character.dart';

const useForgePhysicsBallRotation = false;

class PhysicsBall extends BodyComponent with IgnoreEvents {
  PhysicsBall(
      {Vector2? initialPosition,
      position,
      required this.realCharacter,
      double? size,
      Color? color})
      : super(
            fixtureDefs: [
              FixtureDef(
                CircleShape()
                  ..radius = size ?? maze.spriteWidth() / 2 * 0.99, //0.95
                restitution: 0.0,
                friction: useForgePhysicsBallRotation ? 1 : 0,
                userData: PhysicsBall,
              ),
            ],
            bodyDef: BodyDef(
              angularDamping: useForgePhysicsBallRotation ? 0.1 : 0.1,
              position: initialPosition ?? maze.cage,
              type: BodyType.dynamic,
              userData: PhysicsBall,
            ));

  GameCharacter realCharacter;

  @override
  // ignore: overridden_fields
  final renderBody = false;

  double get speed => body.linearVelocity.length;

  set velocity(Vector2 vel) => body.linearVelocity.setFrom(vel);

  set position(Vector2 pos) => body.setTransform(pos, 0); //realCharacter.angle

  bool subConnectedBall = true;

  void setDynamic() {
    body.setType(BodyType.dynamic);
    body.setActive(true);
    subConnectedBall = true;
  }

  void setStatic() {
    body.setType(BodyType.static);
    body.setActive(false);
    subConnectedBall = false;
  }

  void moveThroughPipePortal() {
    if (subConnectedBall) {
      if (position.x.abs() > maze.mazeWidth / 2 * _portalMargin ||
          position.y.abs() > maze.mazeHeight / 2 * _portalMargin) {
        position = Vector2(_mod(position.x, maze.mazeWidth * _portalMargin),
            _mod(position.y, maze.mazeHeight * _portalMargin));
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    moveThroughPipePortal();
  }
}

const _portalMargin = 0.97;

double _mod(double position, double mod) {
  position = position % mod;
  return position > mod / 2 ? position - mod : position;
}
