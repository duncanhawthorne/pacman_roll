import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import 'game_character.dart';
import '../helper.dart';

class PhysicsBall extends BodyComponent { //with TapCallbacks, ContactCallbacks
  PhysicsBall(
      {Vector2? initialPosition,
      required GameCharacter realCharacter,
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
                friction: useForgePhysicsBallRotation ? 1 : 0,
                userData: PhysicsBall,
              ),
            ],
            bodyDef: BodyDef(
              angularDamping: 0.1,
              position: initialPosition ?? kPacmanStartLocation,
              type: BodyType.dynamic,
              userData: PhysicsBall,
            ),
            paint: Paint()
              ..color = color ?? Colors.transparent
              ..style = PaintingStyle.fill);

  GameCharacter? realCharacter;

  /*
  @override
  Body createBody() {
    if (bodyDef!.userData != null) {
      bodyDef!.userData = this;
    }
    return super.createBody();
  }

   */

  /*
  @override
  // ignore: unnecessary_overrides
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);

    //FIXME un-disable this

    /*
    if (other is PhysicsBall && other.realCharacter != null) {
      if (other.realCharacter != null && realCharacter != null) {
        if (realCharacter is PM) {
          realCharacter!.handlePacmanMeetsGhost(other.realCharacter!);
        }
      } else {
        p("shouldn't have got here");
      }
    }
    */
  }
  */
}
