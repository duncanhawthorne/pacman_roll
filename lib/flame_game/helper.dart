import 'components/pacman.dart';
import 'components/pacman_sprites.dart';
import 'pacman_world.dart';
import 'constants.dart';
import 'saves.dart';
import 'components/game_character.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flame/components.dart';
import 'dart:core';
import 'package:sensors_plus/sensors_plus.dart';
import '../style/palette.dart';
import 'package:flutter/services.dart';

import 'title_fix_stub.dart' if (dart.library.js_interop) 'title_fix_web.dart';

final palette = Palette();

Save save = Save();
PacmanSprites pacmanSprites = PacmanSprites();

double singleSquareWidth() {
  return inGameVectorPixels / getMazeIntWidth() * gameScaleFactor;
}

double spriteWidth() {
  return singleSquareWidth() * (expandedMaze ? 2 : 1);
}

int getMazeIntWidth() {
  return wrappedMazeLayout.isEmpty ? 0 : wrappedMazeLayout[0].length;
}

int numberOfAlivePacman(List<Pacman> pacmanPlayersList) {
  int result = 0;
  for (int i = 0; i<pacmanPlayersList.length; i++) {
    if (pacmanPlayersList[i].current != CharacterState.deadPacman) {
      result++;
    }
  }
  return result;
}

void p(x) {
  // ignore: prefer_interpolation_to_compose_strings
  debugPrint("///// A " + DateTime.now().toString() + " " + x.toString());
}

int getRollSpinDirection(Vector2 vel, Vector2 gravity) {
  if (vel.x.abs() > vel.y.abs()) {
    //moving left or right
    if (gravity.y > 0) {
      //onWall = WallLocation.bottom;
      if ((vel.x) > 0) {
        //clockwise = true;
        return 1;
      } else {
        //clockwise = false;
        return -1;
      }
    } else {
      //onWall = WallLocation.top;
      if ((vel.x) > 0) {
        //clockwise = false;
        return -1;
      } else {
        //clockwise = true;
        return 1;
      }
    }
  } else {
    //moving up or down
    if (gravity.x > 0) {
      //onWall = WallLocation.right;
      if ((vel.y) > 0) {
        //clockwise = false;
        return -1;
      } else {
        //clockwise = true;
        return 1;
      }
    } else {
      //onWall = WallLocation.left;
      if ((vel.y) > 0) {
        //clockwise = true;
        return 1;
      } else {
        //clockwise = false;
        return -1;
      }
    }
  }
}

double convertToSmallestDeltaAngle(double angleDelta) {
  //avoid indicating  +2*pi-delta jump when go around the circle, instead give -delta
  angleDelta = angleDelta + 2 * pi / 2;
  angleDelta = angleDelta % (2 * pi);
  return angleDelta - 2 * pi / 2;
}

double getTargetSirenVolume(PacmanWorld world) {
  if (!world.game.isGameLive()) {
    p("siren 0: game not live");
    return 0;
  }
  double tmpSirenVolume = 0;
  try {
    for (int i = 0; i < world.ghostPlayersList.length; i++) {
      tmpSirenVolume +=
          world.ghostPlayersList[i].current == CharacterState.normal
              ? world.ghostPlayersList[i].getVelocity().length /
                  world.ghostPlayersList.length
              : 0;
    }
    if ((world.pacmanPlayersList.isNotEmpty &&
            world.pacmanPlayersList[0].current == CharacterState.deadPacman) ||
        !world.physicsOn) {
      tmpSirenVolume = 0;
    }
  } catch (e) {
    tmpSirenVolume = 0;
    p([e, "tmpSirenVolume error"]);
  }
  tmpSirenVolume = tmpSirenVolume / 30;
  if (tmpSirenVolume < 0.05) {
    tmpSirenVolume = 0;
  }
  tmpSirenVolume = min(0.4, tmpSirenVolume);
  return tmpSirenVolume;
}

String getRandomString(random, int length) =>
    String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

void legacyHandleAcceleratorEvents(PacmanWorld world) {
  if (useGyro) {
    accelerometerEventStream().listen(
      //start once and then runs
      (AccelerometerEvent event) {
        world.setGravity(
            Vector2(event.y, event.x - 5) * (android && web ? 5 : 1));
      },
      onError: (error) {
        // Logic to handle error
        // Needed for Android in case sensor is not available
      },
      cancelOnError: true,
    );
  }
}

Vector2 getSanitizedScreenSize(Vector2 size) {
  if (size.x > size.y) {
    return Vector2(kSquareNotionalSize * size.x / size.y, kSquareNotionalSize);
  } else {
    return Vector2(kSquareNotionalSize, kSquareNotionalSize * size.y / size.x);
  }
}

void setStatusBarColor(color) {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: color, // Status bar color
  ));
  targetTitleBarColor = color;
}

void fixTitle() {
  fixTitleReal(); //either from web or stub
}

int roundUpToMult(int x, int roundUpMult) {
  return (x / roundUpMult).ceil() * roundUpMult;
}
