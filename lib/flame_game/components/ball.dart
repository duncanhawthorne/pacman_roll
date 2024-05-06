import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import 'player.dart';
import '../helper.dart';

class Ball extends BodyComponent with TapCallbacks, ContactCallbacks {
  Ball(
      {Vector2? initialPosition,
      required RealCharacter realCharacter,
      double? size,
      Color? color})
      : super(
            fixtureDefs: [
              FixtureDef(
                /*
                PolygonShape()..set([
                  Vector2(0.0, getSingleSquareWidth() / 2 * 0.99), // Middle of top wall
                  Vector2(getSingleSquareWidth() / 2 * 0.99, 0.0), // Middle of right wall
                  Vector2(0.0, -getSingleSquareWidth() / 2 * 0.99), // Middle of bottom wall
                  Vector2(-getSingleSquareWidth() / 2 * 0.99, 0.0), // Middle of left wall
                ]),

                 */
                CircleShape()
                  ..radius = size ?? getSingleSquareWidth() / 2 * 0.99, //0.95
                restitution: 0.0,
                friction: 0.1,
                userData: Ball,
              ),
            ],
            bodyDef: BodyDef(
              angularDamping: 0.1,
              position: initialPosition ?? kPacmanStartLocation,
              type: BodyType.dynamic,
              userData: Ball,
            ),
            paint: Paint()
              ..color = color ?? Colors.transparent
              ..style = PaintingStyle.fill);

  RealCharacter? realCharacter;

  /*
  @override
  Body createBody() {
    if (bodyDef!.userData != null) {
      bodyDef!.userData = this;
    }
    return super.createBody();
  }

   */

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);

    if (other is Ball && other.realCharacter != null) {
      if (other.realCharacter != null && realCharacter != null) {
        realCharacter!.handlePacmanMeetsGhost(other.realCharacter!);
      } else {
        p("shouldn't have got here");
      }
    }
  }
}
