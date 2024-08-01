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
}
