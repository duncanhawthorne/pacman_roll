import 'package:flutter/cupertino.dart';

import '../constants.dart';
import '../maze_layout.dart';
import '../helper.dart';
import 'package:flame/components.dart';
import 'wall.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'dart:math';
import 'super_pellet.dart';
import 'mini_pellet.dart';

import 'package:flame/extensions.dart';

int getMazeWidth() {
  return sqrt(flatMazeLayout.length).toInt();
}

void addPelletsAndSuperPellets(
    Forge2DWorld world, ValueNotifier pelletsRemainingNotifier) {
  pelletsRemainingNotifier.value = 0;
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

      if (flatMazeLayout[k] == 0) {
        //var pillx = MiniPellet();
        //pillx.absPosition = location;
        //pillx.position = location; //initial set
        //world.add(pillx);
        world.add(MiniPelletCircle(position: location));
        pelletsRemainingNotifier.value += 1;
      }
      if (flatMazeLayout[k] == 3) {
        //var powerpill = SuperPellet();
        //powerpill.absPosition = location;
        //powerpill.position = location; //initial set
        //world.add(powerpill);

        world.add(SuperPelletCircle(position: location));
        pelletsRemainingNotifier.value += 1;
      }
    }
  }
}

bool wallNeededBetween(int k, int l) {
  int mazeWidth = getMazeWidth();
  return (k > 0 &&
      l > 0 &&
      l < flatMazeLayout.length &&
      k < flatMazeLayout.length &&
      (flatMazeLayout[k] == 1 && flatMazeLayout[l] != 1 ||
          flatMazeLayout[k] != 1 &&
              flatMazeLayout[l] == 1 &&
              (l) % mazeWidth != 0));
}

class MazeWallSquare extends RectangleComponent {
  MazeWallSquare({required super.position})
      : super(
            size: Vector2(getSingleSquareWidth() * 1.03, //.ceil().toDouble()
                getSingleSquareWidth() * 1.03), //.ceil().toDouble()
            anchor: Anchor.center,
            paint: blueMazePaint);
}

void addMazeWalls(world) {
  if (mazeOn) {
    int mazeWidth = getMazeWidth();
    for (var i = 0; i < mazeWidth; i++) {
      for (var j = 0; j < mazeWidth; j++) {
        int k = i * mazeWidth + j;
        double scale = getSingleSquareWidth();
        double A = (j * 1.0 - mazeWidth / 2) * scale;
        double B = (i * 1.0 - mazeWidth / 2) * scale;
        double D = 1.0 * scale;
        double E = 1.0 * scale;
        Vector2 topRight = Vector2(A + D, B);
        Vector2 bottomRight = Vector2(A + D, B + E);
        Vector2 bottomLeft = Vector2(A, B + E);
        Vector2 topLeft = Vector2(A, B);
        Vector2 center = (topRight + bottomLeft) / 2;
        double x = 1 / (sqrt(2) + 1);
        double roundMazeCornersProportion = (1 - x) / 2; //octagonal
        Vector2 vertBit = Vector2(0, roundMazeCornersProportion * scale);
        Vector2 horiBit = Vector2(roundMazeCornersProportion * scale, 0);

        if (wrappedMazeLayout[i][j] == 1) {
          world.add(MazeWallSquare(position: center));
        }

        if (i == 10 && j == 0) {
          assert(wrappedMazeLayout[i][j] == 1);
          world.add(Wall(topRight, bottomRight));
          world.add(Wall(bottomLeft, bottomRight));
          world.add(Wall(bottomLeft, topLeft));
          world.add(Wall(topRight + horiBit, topLeft));
        }

        if (wrappedMazeLayout[i][j] == 1) {
          //square around each point with rounded corners
          if (i - 1 > 0 &&
              j + 1 < mazeWidth &&
              wrappedMazeLayout[i - 1][j] != 1 &&
              wrappedMazeLayout[i - 1][j + 1] != 1 &&
              wrappedMazeLayout[i][j + 1] != 1) {
            world.add(Wall(topRight - horiBit, topRight + vertBit));
          }
          if (i - 1 > 0 &&
              j - 1 > 0 &&
              wrappedMazeLayout[i - 1][j] != 1 &&
              wrappedMazeLayout[i - 1][j - 1] != 1 &&
              wrappedMazeLayout[i][j - 1] != 1) {
            world.add(Wall(topLeft + horiBit, topLeft + vertBit));
          }
          if (i + 1 < mazeWidth &&
              j - 1 > 0 &&
              wrappedMazeLayout[i + 1][j] != 1 &&
              wrappedMazeLayout[i + 1][j - 1] != 1 &&
              wrappedMazeLayout[i][j - 1] != 1) {
            world.add(Wall(bottomLeft + horiBit, bottomLeft - vertBit));
          }
          if (i + 1 < mazeWidth &&
              j + 1 < mazeWidth &&
              wrappedMazeLayout[i + 1][j] != 1 &&
              wrappedMazeLayout[i + 1][j + 1] != 1 &&
              wrappedMazeLayout[i][j + 1] != 1) {
            world.add(Wall(bottomRight - horiBit, bottomRight - vertBit));
          }

          //top right
        }

        if (wallNeededBetween(k, k + 1)) {
          //wall on right
          //world.add(Wall(Vector2(A,B),Vector2(A+D,B)));
          Vector2 a = !wallNeededBetween(k + mazeWidth, k + 1 + mazeWidth)
              ? vertBit
              : Vector2(0, 0);
          Vector2 b = !wallNeededBetween(k - mazeWidth, k + 1 - mazeWidth)
              ? vertBit
              : Vector2(0, 0);
          world.add(Wall(topRight + b, bottomRight - a));
          //world.add(Wall(Vector2(A + D, B + E), Vector2(A, B + E)));
          //world.add(Wall(Vector2(A,B+E),Vector2(A,B)));
        }
        if (wallNeededBetween(k, k + mazeWidth)) {
          Vector2 a = !wallNeededBetween(k + 1, k + 1 + mazeWidth)
              ? horiBit
              : Vector2(0, 0);
          Vector2 b = !wallNeededBetween(k - 1, k - 1 + mazeWidth)
              ? horiBit
              : Vector2(0, 0);
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
