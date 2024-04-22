import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'components/wall.dart';
import 'components/powerpoint.dart';
import 'components/point.dart';
import 'constants.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'components/player.dart';

void p(x) {
  // ignore: prefer_interpolation_to_compose_strings
  debugPrint("///// A " + DateTime.now().toString() + " " + x.toString());
}

int getMagicParity() {
  int diry = 1;
  if (globalGravity.y > 0) {
    diry = 1;
  } else {
    diry = -1;
  }

  int dirx = 1;
  if (globalGravity.x > 0) {
    dirx = 1;
  } else {
    dirx = -1;
  }

  int dirside = 1;
  if ((globalGravity.x).abs() > (globalGravity.y).abs()) {
    dirside = 1;
  } else {
    dirside = -1;
  }

  int magicparity = diry * dirx * dirside;
  return magicparity;
}

List<VisiblePlayer> ghostPlayersList = [];

void addGhost(world, int number) {
  VisiblePlayer ghost = VisiblePlayer(isGhost: true, startPosition: kGhostStartLocation + Vector2.random() / 100);
  ghost.ghostNumber = number;
  world.add(ghost);
  //ghost.moveUnderlyingBallToVector(
  //    kGhostStartLocation + Vector2.random() / 100);
  ghostPlayersList.add(ghost);
}

void removeGhost(VisiblePlayer otherPlayer) {
  otherPlayer.removeFromParent();
  otherPlayer.underlyingBallReal.removeFromParent();
  ghostPlayersList.remove(otherPlayer);
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

void addPillsAndPowerPills(world) {
  double sizex = ksizex;
  double sizey = ksizey;
  for (var i = 0; i < mazelen ; i++) {
    for (var j = 0; j < mazelen; j++) {
      int k = j * mazelen + i;
      double scalex = sizex / dzoom / mazelen;
      double scaley = sizey / dzoom / mazelen;
      scalex = min(scalex, scaley);
      scaley = min(scalex, scaley);
      double A = (i * 1.0 - mazelen  / 2) * scalex;
      double B = (j * 1.0 - mazelen / 2) * scaley;
      double D = 1.0 * scalex;
      double E = 1.0 * scaley;
      Vector2 location = Vector2(A + D / 2, B + E / 2);

      if (mazeLayout[k] == 0) {
        var pillx = MiniPellet();
        pillx.position = location;
        world.add(pillx);
      }
      if (mazeLayout[k] == 3) {
        var powerpill = SuperPellet();
        powerpill.position = location;
        world.add(powerpill);
      }
    }
  }
}
