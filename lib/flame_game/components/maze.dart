import '../constants.dart';
import '../helper.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'wall.dart';

import 'package:flame/extensions.dart';

void createMaze(double sizex, double sizey, world) {
  if (mazeOn) {
    for (var i = 0; i < mazelen; i++) {
      for (var j = 0; j < mazelen; j++) {
        int k = j * mazelen + i;
        double scalex = getSingleSquareWidth();
        double scaley = getSingleSquareWidth();
        double A = (i * 1.0 - mazelen / 2) * scalex;
        double B = (j * 1.0 - mazelen / 2) * scaley;
        double D = 1.0 * scalex;
        double E = 1.0 * scaley;
        if (k + 1 < mazeLayout.length &&
            (mazeLayout[k] == 1 && mazeLayout[k + 1] != 1 ||
                mazeLayout[k] != 1 && mazeLayout[k + 1] == 1)) {
          //world.add(Wall(Vector2(A,B),Vector2(A+D,B)));
          world.add(Wall(Vector2(A + D, B), Vector2(A + D, B + E)));
          //world.add(Wall(Vector2(A + D, B + E), Vector2(A, B + E)));
          //world.add(Wall(Vector2(A,B+E),Vector2(A,B)));
        }
        if (k + mazelen < mazeLayout.length &&
            (mazeLayout[k] == 1 && mazeLayout[k + mazelen] != 1 ||
                mazeLayout[k] != 1 && mazeLayout[k + mazelen] == 1)) {
          //world.add(Wall(Vector2(A,B),Vector2(A+D,B)));
          //world.add(Wall(Vector2(A + D, B), Vector2(A + D, B + E)));
          world.add(Wall(Vector2(A + D, B + E), Vector2(A, B + E)));
          //world.add(Wall(Vector2(A,B+E),Vector2(A,B)));
        }
      }
    }
  }
}
