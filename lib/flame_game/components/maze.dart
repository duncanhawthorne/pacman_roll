import '../constants.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import 'dart:math';
import 'wall.dart';

import 'package:flame/extensions.dart';

void createMaze(double sizex, double sizey, world) {
  if (mazeOn) {
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
        if (mazeLayout[k] == 1) {
/*
          world.add(Wall(Vector2(A,B),Vector2(A+D,B)));
          world.add(Wall(Vector2(A+D,B),Vector2(A+D,B+E)));
          world.add(Wall(Vector2(A+D,B+E),Vector2(A,B+E)));
          world.add(Wall(Vector2(A,B+E),Vector2(A,B)));

 */
        }
        if (k + 1 < 28 * 28 &&
            (mazeLayout[k] == 1 && mazeLayout[k + 1] != 1 ||
                mazeLayout[k] != 1 && mazeLayout[k + 1] == 1)) {
          //world.add(Wall(Vector2(A,B),Vector2(A+D,B)));
          //world.add(Wall(Vector2(A+D,B),Vector2(A+D,B+E)));
          world.add(Wall(Vector2(A + D, B + E), Vector2(A, B + E)));
          //world.add(Wall(Vector2(A,B+E),Vector2(A,B)));
        }
        if (k + 28 < 28 * 28 &&
            (mazeLayout[k] == 1 && mazeLayout[k + 28] != 1 ||
                mazeLayout[k] != 1 && mazeLayout[k + 28] == 1)) {
          //world.add(Wall(Vector2(A,B),Vector2(A+D,B)));
          world.add(Wall(Vector2(A + D, B), Vector2(A + D, B + E)));
          //world.add(Wall(Vector2(A+D,B+E),Vector2(A,B+E)));
          //world.add(Wall(Vector2(A,B+E),Vector2(A,B)));
        }
      }
    }
  }
}
