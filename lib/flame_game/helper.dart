import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'components/wall.dart';
import 'components/player.dart';
import 'components/powerpoint.dart';
import 'components/point.dart';
import 'constants.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

void p(x) {
  // ignore: prefer_interpolation_to_compose_strings
  debugPrint("///// A " + DateTime.now().toString() + " " + x.toString());
}

int getStartingNumberPelletsAndSuperPellets() {
  int c = 0;
  c += mazeLayout
      .map((element) => element == 0 ? 1 : 0)
      .reduce((value, element) => value + element);
  c += mazeLayout
      .map((element) => element == 3 ? 1 : 0)
      .reduce((value, element) => value + element);
  return c;
}

double getSingleSquareWidth() {
  return min(ksizex, ksizey) / flameGameZoom / getMazeWidth() * gameScaleFactor;
}

int getMazeWidth() {
  return sqrt(mazeLayout.length).toInt();
}

List<RealCharacter> ghostPlayersList = [];

void addGhost(world, int number) {
  RealCharacter ghost = RealCharacter(
      isGhost: true,
      startPosition: kGhostStartLocation +
          Vector2(getSingleSquareWidth() * (number - 1), 0));
  ghost.ghostNumber = number;
  world.add(ghost);
  ghostPlayersList.add(ghost);
}

Vector2 screenPos(double worldAngle, Vector2 absolutePos) {
  if (!screenRotates) {
    return absolutePos;
  } else {
    Matrix2 mat = Matrix2(
        cos(worldAngle), -sin(worldAngle), sin(worldAngle), cos(worldAngle));
    return Vector2(mat[0] * absolutePos[0] + mat[1] * absolutePos[1],
        mat[2] * absolutePos[0] + mat[3] * absolutePos[1]);
  }
}

enum WallLocation { bottom, top, left, right }

int getRollSpinDirection(
    Forge2DWorld world, Vector2 vel, Vector2 gravityWeCareAbout) {
  double velx = vel.x;
  double vely = vel.y;
  //FIXME probably can be dramatically simplified

  WallLocation onWall = WallLocation.bottom;
  bool clockwise = true;
  //Vector2 gravityWeCareAbout = globalGravity; //world.gravity;
  double small = 4;

  if (velx.abs() > small) {
    //moving left or right
    if (gravityWeCareAbout.y > 0) {
      onWall = WallLocation.bottom;
    } else {
      onWall = WallLocation.top;
    }
  } else if (vely.abs() > small) {
    //moving up or down
    if (gravityWeCareAbout.x > 0) {
      onWall = WallLocation.right;
    } else {
      onWall = WallLocation.left;
    }
  }

  if (onWall == WallLocation.bottom) {
    if ((velx) > 0) {
      clockwise = true;
    } else {
      clockwise = false;
    }
  }

  if (onWall == WallLocation.top) {
    if ((velx) > 0) {
      clockwise = false;
    } else {
      clockwise = true;
    }
  }

  if (onWall == WallLocation.left) {
    if ((vely) > 0) {
      clockwise = true;
    } else {
      clockwise = false;
    }
  }

  if (onWall == WallLocation.right) {
    if ((vely) > 0) {
      clockwise = false;
    } else {
      clockwise = true;
    }
  }

  if (clockwise) {
    return 1;
  } else {
    return -1;
  }
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

void addPillsAndPowerPills(world) {
  int mazelen = getMazeWidth();
  for (var i = 0; i < mazelen; i++) {
    for (var j = 0; j < mazelen; j++) {
      int k = j * mazelen + i;
      double scalex = getSingleSquareWidth();
      double scaley = getSingleSquareWidth();
      double A = (i * 1.0 - mazelen / 2) * scalex;
      double B = (j * 1.0 - mazelen / 2) * scaley;
      double D = 1.0 * scalex;
      double E = 1.0 * scaley;
      Vector2 location = Vector2(A + D / 2, B + E / 2);

      if (mazeLayout[k] == 0) {
        var pillx = MiniPellet();
        pillx.absPosition = location;
        world.add(pillx);
      }
      if (mazeLayout[k] == 3) {
        var powerpill = SuperPellet();
        powerpill.absPosition = location;
        world.add(powerpill);
      }
    }
  }
}
