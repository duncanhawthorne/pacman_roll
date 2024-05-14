import 'package:pacman_roll/flame_game/endless_world.dart';

import 'components/maze_walls.dart';
import 'constants.dart';
import 'saves.dart';
import 'components/game_character.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flame/components.dart';
import 'dart:core';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:sensors_plus/sensors_plus.dart';
import '../style/palette.dart';
import 'package:flutter/services.dart';

final palette = Palette();

Save save = Save();

double getSingleSquareWidth() {
  return inGameVectorPixels / getMazeWidth() * gameScaleFactor;
}

void p(x) {
  // ignore: prefer_interpolation_to_compose_strings
  debugPrint("///// A " + DateTime.now().toString() + " " + x.toString());
}

String endText(double value) {
  double x = percentile(scoreboardItemsDoubles, value) * 100;
  String y =
      "\nTime: ${value.toStringAsFixed(1)} seconds \n\nRank: Top ${x.toStringAsFixed(0)}%\n";
  return y;
}

double percentile(List<double> list, double value) {
  List<double> newList = List<double>.from(list);
  newList.add(value);
  newList.sort();
  return newList.indexOf(value) / newList.length;
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

enum WallLocation { bottom, top, left, right }

int getRollSpinDirection(Vector2 vel, Vector2 gravity) {
  WallLocation onWall = WallLocation.bottom;
  bool clockwise = true;
  double smallThresholdVelocity = 4;

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
  }

  if (onWall == WallLocation.top) {
    if ((vel.x) > 0) {
      clockwise = false;
    } else {
      clockwise = true;
    }
  }

  if (onWall == WallLocation.left) {
    if ((vel.y) > 0) {
      clockwise = true;
    } else {
      clockwise = false;
    }
  }

  if (onWall == WallLocation.right) {
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

// With the `TextPaint` we define what properties the text that we are going
// to render will have, like font family, size and color in this instance.
final textRenderer = TextPaint(
  style: const TextStyle(
    fontSize: 30,
    color: Colors.white,
    fontFamily: 'Press Start 2P',
  ),
);

final Paint blueMazePaint = Paint()
  ..color = const Color(0xFF3B32D4); //blue; //yellowAccent;
final Paint pacmanYellowPaint = Paint()
  ..color = Colors.yellowAccent; //blue; //yellowAccent;
final Rect rectSingleSquare = Rect.fromCenter(
    center: Offset(getSingleSquareWidth() / 2, getSingleSquareWidth() / 2),
    width: getSingleSquareWidth(),
    height: getSingleSquareWidth());
final Rect rect100 = Rect.fromCenter(
    center: const Offset(100 / 2, 100 / 2), width: 100, height: 100);

ui.Image pacmanStandardImage() {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  const mouthWidth = pacmanMouthWidthDefault;
  canvas.drawArc(rect100, 2 * pi * ((mouthWidth / 2) + 0.5),
      2 * pi * (1 - mouthWidth), true, pacmanYellowPaint);
  return recorder.endRecording().toImageSync(100, 100);
}

ui.Image pacmanMouthClosedImage() {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  const mouthWidth = 0;
  canvas.drawArc(rect100, 2 * pi * ((mouthWidth / 2) + 0.5),
      2 * pi * (1 - mouthWidth), true, pacmanYellowPaint);
  return recorder.endRecording().toImageSync(100, 100);
}

pureVectorPacman() {
  double pfrac = 5 / 32;
  double pangle = pfrac * 2 * pi / 2;
  return ClipComponent.polygon(
    points: [
      Vector2(1, 0),
      Vector2(0, 0),
      Vector2(0, 1),
      Vector2(1, 1),
      pfrac > 0.5 ? Vector2(0, 1) : Vector2(1, 1),
      Vector2(0.5 + cos(pangle) / 2, 0.5 + sin(pangle) / 2),
      Vector2(0.5, 0.5),
      Vector2(0.5 + cos(pangle) / 2, 0.5 - sin(pangle) / 2),
      pfrac > 0.5 ? Vector2(0, 0) : Vector2(1, 0),
      Vector2(1, 0),
    ],
    position: Vector2(0, 0),
    size: Vector2.all(getSingleSquareWidth()),
    children: [
      CircleComponent(
          radius: getSingleSquareWidth() / 2, paint: pacmanYellowPaint),
    ],
  );
}

double getTargetSirenVolume(
    isgameliveTmp, ghostPlayersList, pacmanPlayersList) {
  if (!isgameliveTmp) {
    p("siren 0: game not live");
    return 0;
  }
  double tmpSirenVolume = 0;
  try {
    for (int i = 0; i < ghostPlayersList.length; i++) {
      tmpSirenVolume += ghostPlayersList[i].current == CharacterState.normal
          ? ghostPlayersList[i].getUnderlyingBallVelocity().length /
              ghostPlayersList.length
          : 0;
    }
    if ((pacmanPlayersList.isNotEmpty &&
            pacmanPlayersList[0].current == CharacterState.deadPacman) ||
        !globalPhysicsLinked) {
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
