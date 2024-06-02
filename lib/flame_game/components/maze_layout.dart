//import 'package:flutter/cupertino.dart';

import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../helper.dart';
import 'package:flame/components.dart';
import 'wall.dart';
import 'super_pellet.dart';
import 'mini_pellet.dart';

import 'package:flame/extensions.dart';

const mazeWallWidthFactor = 0.7;

List<Component> pelletsAndSuperPellets(ValueNotifier pelletsRemainingNotifier) {
  List<Component> result = [];
  pelletsRemainingNotifier.value = 0;
  double scale = blockWidth();
  for (int i = 0; i < wrappedMazeLayout.length; i++) {
    for (int j = 0; j < wrappedMazeLayout[i].length; j++) {
      Vector2 center = Vector2(0, 0);
      if (expandedMaze) {
        center = Vector2(j + 1 - wrappedMazeLayout[0].length / 2,
                i + 1 - wrappedMazeLayout.length / 2) *
            scale;
      } else {
        center = Vector2(j + 1 / 2 - wrappedMazeLayout[0].length / 2,
                i + 1 / 2 - wrappedMazeLayout.length / 2) *
            scale;
      }
      if (wrappedMazeLayout[i][j] == 0) {
        result.add(MiniPelletCircle(position: center));
      }
      if (wrappedMazeLayout[i][j] == 3) {
        result.add(SuperPelletCircle(position: center));
      }
    }
  }
  return result;
}

class MazeWallSquareVisual extends RectangleComponent {
  MazeWallSquareVisual(
      {required super.position, required widthx, required heightx})
      : super(
            size: Vector2(widthx, heightx),
            anchor: Anchor.center,
            paint: blackBackgroundPaint);
  double widthx = 0;
  double heightx = 0;
}

class MazeWallCircleVisual extends CircleComponent {
  MazeWallCircleVisual({required super.radius, required super.position})
      : super(anchor: Anchor.center, paint: blackBackgroundPaint); //NOTE BLACK
}

bool mazeWallAt(int i, int j) {
  if (i >= wrappedMazeLayout.length ||
      i < 0 ||
      j >= wrappedMazeLayout[i].length ||
      j < 0) {
    return false;
  } else {
    return wrappedMazeLayout[i][j] == 1;
  }
}

bool circleAt(int i, int j) {
  assert(mazeWallAt(i, j));
  return !(mazeWallAt(i - 1, j) && mazeWallAt(i + 1, j) ||
      mazeWallAt(i, j - 1) && mazeWallAt(i, j + 1));
}

const double pixelationBuffer = 1.03;

List<Component> mazeWalls() {
  List<Component> result = [];
  double scale = blockWidth();
  if (mazeOn) {
    for (int i = 0; i < wrappedMazeLayout.length; i++) {
      for (int j = 0; j < wrappedMazeLayout[i].length; j++) {
        Vector2 center = Vector2(j + 1 / 2 - wrappedMazeLayout[0].length / 2,
                i + 1 / 2 - wrappedMazeLayout.length / 2) *
            scale;
        if (mazeWallAt(i, j)) {
          if (circleAt(i, j)) {
            result.add(MazeWallCircleGround(center, scale / 2));
          }
          if (mazeWallAt(i, j + 1)) {
            result.add(MazeWallRectangleGround(center + Vector2(scale / 2, 0),
                scale * pixelationBuffer, scale));
          }
          if (mazeWallAt(i + 1, j)) {
            result.add(MazeWallRectangleGround(center + Vector2(0, scale / 2),
                scale, scale * pixelationBuffer));
          }
        }
      }
    }

    for (int i = 0; i < wrappedMazeLayout.length; i++) {
      for (int j = 0; j < wrappedMazeLayout[i].length; j++) {
        Vector2 center = Vector2(j + 1 / 2 - wrappedMazeLayout[0].length / 2,
                i + 1 / 2 - wrappedMazeLayout.length / 2) *
            scale;
        if (mazeWallAt(i, j)) {
          if (circleAt(i, j)) {
            result.add(MazeWallCircleVisual(
                position: center, radius: scale / 2 * mazeWallWidthFactor));
          }
          if (mazeWallAt(i, j + 1)) {
            result.add(MazeWallSquareVisual(
                position: center + Vector2(scale / 2, 0),
                widthx: scale * pixelationBuffer,
                heightx: scale * mazeWallWidthFactor));
          }
          if (mazeWallAt(i + 1, j)) {
            result.add(MazeWallSquareVisual(
                position: center + Vector2(0, scale / 2),
                widthx: scale * mazeWallWidthFactor,
                heightx: scale * pixelationBuffer));
          }
        }
      }
    }
  }
  return result;
}

List<Component> screenEdgeBoundaries(CameraComponent camera) {
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

/*
int getStartingNumberPelletsAndSuperPellets(List mazeLayout) {
  int c = 0;
  c += mazeLayout
      .map((element) => element == 0 ? 1 : 0)
      .reduce((value, element) => value + element);
  c += mazeLayout
      .map((element) => element == 3 ? 1 : 0)
      .reduce((value, element) => value + element);
  return c;
}
 */
