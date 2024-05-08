import '../constants.dart';
import '../helper.dart';
import 'package:flame/components.dart';
import 'wall.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'dart:math';
import 'powerpoint.dart';
import 'point.dart';

import 'package:flame/extensions.dart';

int getMazeWidth() {
  return sqrt(mazeLayout.length).toInt();
}

void addPelletsAndSuperPellets(Forge2DWorld world) {
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
        pillx.position = location; //initial set
        world.add(pillx);
      }
      if (mazeLayout[k] == 3) {
        var powerpill = SuperPellet();
        powerpill.absPosition = location;
        powerpill.position = location; //initial set
        world.add(powerpill);
      }
    }
  }
}

bool wallNeededBetween(int k, int l) {
  int mazeWidth = getMazeWidth();
  return (l < mazeLayout.length &&
      (mazeLayout[k] == 1 && mazeLayout[l] != 1 ||
          mazeLayout[k] != 1 &&
              mazeLayout[l] == 1 &&
              (l) % mazeWidth != 0));
}


void addMazeWalls(world) {
  if (mazeOn) {
    int mazeWidth = getMazeWidth();
    for (var i = 0; i < mazeWidth; i++) {
      for (var j = 0; j < mazeWidth; j++) {
        int k = j * mazeWidth + i;
        double scale = getSingleSquareWidth();
        double A = (i * 1.0 - mazeWidth / 2) * scale;
        double B = (j * 1.0 - mazeWidth / 2) * scale;
        double D = 1.0 * scale;
        double E = 1.0 * scale;
        Vector2 topRight = Vector2(A + D, B);
        Vector2 bottomRight = Vector2(A + D, B + E);
        Vector2 bottomLeft = Vector2(A, B + E);
        double rounding = 0.2;
        Vector2 vertBit = Vector2(0, rounding * scale);
        Vector2 horiBit = Vector2(rounding * scale, 0);

        /*
        if (mazeLayout[k] == 1) {
          if (wallNeededBetween(k, k+1)) {
            Vector2 a = !wallNeededBetween(k+mazeWidth, k+1+mazeWidth) ? vertBit : Vector2(0,0);
            Vector2 b = !wallNeededBetween(k-mazeWidth, k+1-mazeWidth) ? vertBit : Vector2(0,0);
            world.add(Wall(topRight + b, bottomRight - a));
          }
        }

         */



        if (wallNeededBetween(k, k+1)) {
          //wall on right
          //world.add(Wall(Vector2(A,B),Vector2(A+D,B)));
          Vector2 a = !wallNeededBetween(k+mazeWidth, k+1+mazeWidth) ? vertBit : Vector2(0,0);
          Vector2 b = !wallNeededBetween(k-mazeWidth, k+1-mazeWidth) ? vertBit : Vector2(0,0);
          world.add(Wall(topRight + b, bottomRight - a));
          //world.add(Wall(Vector2(A + D, B + E), Vector2(A, B + E)));
          //world.add(Wall(Vector2(A,B+E),Vector2(A,B)));
        }
        if (wallNeededBetween(k, k+mazeWidth)) {
          Vector2 a = !wallNeededBetween(k+1, k+1+mazeWidth) ? horiBit : Vector2(0,0);
          Vector2 b = !wallNeededBetween(k-1, k-1+mazeWidth) ? horiBit : Vector2(0,0);
          //world.add(Wall(Vector2(A,B),Vector2(A+D,B)));
          //world.add(Wall(Vector2(A + D, B), Vector2(A + D, B + E)));
          world.add(Wall(bottomRight - a, bottomLeft + b));
          //world.add(Wall(Vector2(A,B+E),Vector2(A,B)));
        }
      }
    }
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
