import 'endless_world.dart';
import 'constants.dart';
import 'saves.dart';
import 'components/game_character.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flame/components.dart';
import 'dart:core';
import 'dart:ui';
import 'package:sensors_plus/sensors_plus.dart';
import '../style/palette.dart';
import 'package:flutter/services.dart';

import 'title_fix_stub.dart' if (dart.library.js_interop) 'title_fix_web.dart';

final palette = Palette();

Save save = Save();

double getSingleSquareWidth() {
  return inGameVectorPixels / getMazeIntWidth() * gameScaleFactor;
}

double spriteWidth() {
  return getSingleSquareWidth() * (expandedMaze ? 2 : 1);
}

int getMazeIntWidth() {
  return wrappedMazeLayout.isEmpty ? 0 : wrappedMazeLayout[0].length;
}

void p(x) {
  // ignore: prefer_interpolation_to_compose_strings
  debugPrint("///// A " + DateTime.now().toString() + " " + x.toString());
}

enum WallLocation { bottom, top, left, right }

int getRollSpinDirection(Vector2 vel, Vector2 gravity) {
  WallLocation onWall = WallLocation.bottom;
  bool clockwise = true;
  double smallThresholdVelocity = 80 / flameGameZoom;

  if (vel.x.abs() > smallThresholdVelocity) {
    //moving left or right
    if (gravity.y > 0) {
      onWall = WallLocation.bottom;
    } else {
      onWall = WallLocation.top;
    }
  } else if (vel.y.abs() > smallThresholdVelocity) {
    //moving up or down
    if (gravity.x > 0) {
      onWall = WallLocation.right;
    } else {
      onWall = WallLocation.left;
    }
  }

  if (onWall == WallLocation.bottom) {
    if ((vel.x) > 0) {
      clockwise = true;
    } else {
      clockwise = false;
    }
  } else if (onWall == WallLocation.top) {
    if ((vel.x) > 0) {
      clockwise = false;
    } else {
      clockwise = true;
    }
  } else if (onWall == WallLocation.left) {
    if ((vel.y) > 0) {
      clockwise = true;
    } else {
      clockwise = false;
    }
  } else if (onWall == WallLocation.right) {
    if ((vel.y) > 0) {
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

double convertToSmallestDeltaAngle(double angleDelta) {
  //avoid indicating  +2*pi-delta jump when go around the circle, instead give -delta
  angleDelta = angleDelta + 2 * pi / 2;
  angleDelta = angleDelta % (2 * pi);
  return angleDelta - 2 * pi / 2;
}

Sprite pacmanImageAtFracNonAsync(int mouthWidthAsInt) {
  double mouthWidth = mouthWidthAsInt / pacmanRenderFracIncrementsNumber;
  mouthWidth = max(0, min(1, mouthWidth));
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawArc(pacmanRect, 2 * pi * ((mouthWidth / 2) + 0.5),
      2 * pi * (1 - mouthWidth), true, yellowPacmanPaint);
  return Sprite(
      recorder.endRecording().toImageSync(pacmanRectSize, pacmanRectSize));
}

/*
Future<Sprite> pacmanImageAtFrac(double mouthWidth) async {
   return pacmanImageAtFracNonAsync(mouthWidth);
}

Map<int, Sprite> pacmanSpritesAtFrac = {};

Future<void> fillOutPacmanSpritesAtFrac() async {
  for (int index = 0; index < pacmanRenderFracIncrementsNumber + 1; index++) {
    pacmanSpritesAtFrac[index] = await pacmanImageAtFrac(index / pacmanRenderFracIncrementsNumber);
  }
}

/*
final List<Sprite> pacmanSpritesAtFrac = List<Sprite>.generate(
    pacmanRenderFracIncrementsNumber + 1, //open and close
    (int index) =>
        Sprite(pacmanImageAtFrac(index / pacmanRenderFracIncrementsNumber)),
    growable: true);
 */

Sprite pacmanSpriteAtFrac(double frac) {
  frac = max(0, min(1, frac));
  int fracInt = (frac * pacmanRenderFracIncrementsNumber).ceil();
  if (!pacmanSpritesAtFrac.keys.contains(fracInt)) {
    p("manual load");
    pacmanSpritesAtFrac[fracInt] = pacmanImageAtFracNonAsync(fracInt / pacmanRenderFracIncrementsNumber);
  }
  return pacmanSpritesAtFrac[fracInt]!;
}

 */

double getTargetSirenVolume(EndlessWorld world) {
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
        !world.globalPhysicsLinked) {
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

void handleAcceleratorEvents(EndlessWorld world) {
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

Vector2 sanitizeScreenSize(Vector2 size) {
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
}

void fixTitle() {
  fixTitleReal(); //either from web or stub
}

int roundUpToMult(int x, int roundUpMult) {
  return (x / roundUpMult).ceil() * roundUpMult;
}
