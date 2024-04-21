
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'components/wall.dart';
import 'components/ball.dart';
import 'components/powerpoint.dart';
import 'components/point.dart';
import 'constants.dart';
import'dart:math';
import 'package:flutter/material.dart';
import 'components/player.dart';

void p(x) {
  // ignore: prefer_interpolation_to_compose_strings
  debugPrint("///// A " + DateTime.now().toString() + " " + x.toString());
}

void addEnemy(world) {
  Ball ghostBall = Ball(
      size: ksizey / dzoom / 2 / 14 / 2 * 0.95,
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

void removeEnemy(Ball other) {
  other.realCharacter!.removeFromParent();
  other.removeFromParent();
}


List<Component> createBoundaries(CameraComponent camera) {
  final Rect visibleRect = camera.visibleWorldRect;
  final Vector2 topLeft = visibleRect.topLeft.toVector2();
  final Vector2 topRight = visibleRect.topRight.toVector2();
  final Vector2 bottomRight = visibleRect.bottomRight.toVector2();
  final Vector2 bottomLeft = visibleRect.bottomLeft.toVector2();

  return [
    Wall(topLeft, topRight),
    Wall(topRight, bottomRight),
    Wall(bottomLeft, bottomRight),
    Wall(topLeft, bottomLeft),
  ];
}

Vector2 getTarget(Vector2 localPosition, Vector2 size) {
  return Vector2(
      min(size.x / dzoom / 2, max(-size.x / dzoom / 2, localPosition.x)),
      min(size.y / dzoom / 2 * 10 / 10,
          max(size.y / dzoom / 2 * 0 / 10, localPosition.y)));
}

void addPillsAndPowerPills(world, double sizex, double sizey) {
  for (var i = 0; i < 28; i++) {
    for (var j = 0; j < 28; j++) {
      int k = i * 28 + j;
      double scalex = sizex / dzoom / 2 / 14;
      double scaley = sizey / dzoom / 2 / 14;
      scalex = min(scalex, scaley);
      scaley = min(scalex, scaley);
      double A = (i * 1.0 - 14) * scalex;
      double B = (j * 1.0 - 14) * scaley;
      double D = 1.0 * scalex;
      double E = 1.0 * scaley;
      Vector2 location = Vector2(A + D / 2, B + E / 2);

      if (mazeLayout[k] == 0) {
        var pillx = Point();
        pillx.position = location;
        world.add(pillx);
      }
      if (mazeLayout[k] == 3) {
        var powerpill = Powerpoint();
        powerpill.position = location;
        world.add(powerpill);
      }
    }
  }
}