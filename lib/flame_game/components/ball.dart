import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import 'player.dart';
import '../effects/hurt_effect.dart';
import '../helper.dart';
import 'dart:math';

class Ball extends BodyComponent with TapCallbacks, ContactCallbacks {
  Ball({Vector2? initialPosition, double? size, Color? color})
      : super(
            fixtureDefs: [
              FixtureDef(
                CircleShape()..radius = size ?? min(ksizey,ksizex) / dzoom / 2 / 14 / 2 * 0.95,
                restitution: 0.6,
                friction: 0.1,
                userData: Ball,
              ),
            ],
            bodyDef: BodyDef(
              angularDamping: 0.1,
              position: initialPosition ?? Vector2(20, 0),
              type: BodyType.dynamic,
              userData: Ball,
            ),
            paint: Paint()
              ..color = color ?? Colors.transparent
              ..style = PaintingStyle.fill);

  bool ghostBall = false;
  Player? realCharacter;

  @override
  Body createBody() {
    if (bodyDef!.userData != null) {
      bodyDef!.userData = this;
    }
    return super.createBody();
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);

    if (other is Ball) {
      if (other.ghostBall && !ghostBall) {
        if (realCharacter != null && realCharacter!.maniacMode) {
          removeEnemy(other);
          addEnemy(world);
        } else {
          realCharacter!.add(HurtEffect());
        }
      }
    }
  }
}
