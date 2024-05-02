import 'components/maze.dart';
import 'constants.dart';
import 'package:flutter/material.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

double getSingleSquareWidth() {
  return kSquareNotionalSize / flameGameZoom / getMazeWidth() * gameScaleFactor;
}

void p(x) {
  // ignore: prefer_interpolation_to_compose_strings
  debugPrint("///// A " + DateTime.now().toString() + " " + x.toString());
}

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


