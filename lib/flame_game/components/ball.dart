
import 'package:flame_forge2d/flame_forge2d.dart';

import 'package:flame/events.dart';

import 'package:flutter/material.dart';


import '../constants.dart';
import 'player.dart';
import '../effects/hurt_effect.dart';


void addEnemy(world, double sizey) {
  Ball x = Ball(
      size: sizey / dzoom / 2 / 14 / 2 * 0.95,
      color: Colors.transparent,
      enemy: true);
  x.enemy = true;
  x.bodyDef!.position = Vector2(0, 0);
  world.add(x);

  Player ghost = Player(
    realIsGhost: true
    //position: Vector2(boat.position.x, boat.position.y),
    //addScore: addScore,
    //resetScore: resetScore,
  );
  world.add(ghost);
  //ghost.isGhost = true;

  x.ballPlayerLink = ghost;
  ghost.playerTargetBall = x;
}

class Ball extends BodyComponent with TapCallbacks, ContactCallbacks {
  Ball({Vector2? initialPosition, double? size, Color? color, bool? enemy})
      : super(
      fixtureDefs: [
        FixtureDef(
          CircleShape()..radius = size ?? 20 / dzoom,
          restitution: 0.6,
          friction: 0.1,
          userData: Ball,
        ),
      ],
      bodyDef: BodyDef(
        angularDamping: 0.1,
        position: initialPosition ?? Vector2(20,0),
        type: BodyType.dynamic,
        userData: Ball,
      ),
      paint: Paint()
        ..color = color ?? Colors.transparent
        ..style = PaintingStyle.fill);

  bool enemy = false;
  Player? ballPlayerLink;


  @override
  Body createBody() {
    if (bodyDef!.userData != null) {
      bodyDef!.userData = this;
    }
    return super.createBody();
  }

  /*
  @override
  Future<void> onLoad() async {
    final defaultPaint = Paint()
      ..color = _defaultColor
      ..style = PaintingStyle.stroke;
  }

   */

  @override
  void onTapDown(event) {
    body.applyLinearImpulse(Vector2(0, -50000000 * 20 / dzoom));
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    //p("BALL CONTACT");
    //p(other);
    if (other is Ball) {// || other is Pill) {
      //&&
      //world.remove(other);
      /*
      if (other is Pill) {
        p("PILL REMOVE");
        other.removeFromParent();
      } else

       */
      if (other.enemy && !enemy) {
        if (ballPlayerLink != null && ballPlayerLink!.maniacMode) {
          other.ballPlayerLink!.removeFromParent();
          other.removeFromParent();
          addEnemy(world, ksizey);

        }
        else {
          ballPlayerLink!.add(HurtEffect());
        }
        //other.bodyDef!.position = Vector2(0,0);
      }
      // Do something here.
    }
  }
}