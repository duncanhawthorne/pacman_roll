import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import 'player.dart';
import '../effects/hurt_effect.dart';

void addEnemy(world, double sizey) {
  Ball ghostBall = Ball(
      size: sizey / dzoom / 2 / 14 / 2 * 0.95,
      color: Colors.transparent,
      enemy: true);
  ghostBall.enemy = true;
  ghostBall.bodyDef!.position = Vector2(0, 0);
  world.add(ghostBall);

  Player ghost = Player(realIsGhost: true
      );
  world.add(ghost);
  ghostBall.realCharacter = ghost;
  ghost.underlyingBall = ghostBall;
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
              position: initialPosition ?? Vector2(20, 0),
              type: BodyType.dynamic,
              userData: Ball,
            ),
            paint: Paint()
              ..color = color ?? Colors.transparent
              ..style = PaintingStyle.fill);

  bool enemy = false;
  Player? realCharacter;

  @override
  Body createBody() {
    if (bodyDef!.userData != null) {
      bodyDef!.userData = this;
    }
    return super.createBody();
  }

  @override
  void onTapDown(event) {
    body.applyLinearImpulse(Vector2(0, -50000000 * 20 / dzoom));
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is Ball) {
      if (other.enemy && !enemy) {
        if (realCharacter != null && realCharacter!.maniacMode) {
          other.realCharacter!.removeFromParent();
          other.removeFromParent();
          addEnemy(world, ksizey);
        } else {
          realCharacter!.add(HurtEffect());
        }
      }
    }
  }
}
