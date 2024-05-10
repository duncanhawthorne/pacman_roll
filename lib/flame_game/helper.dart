import 'components/maze_walls.dart';
import 'constants.dart';
import 'saves.dart';
import 'components/game_character.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'dart:core';
import 'dart:ui' as ui;
import 'dart:ui';

Save save = Save();

double getSingleSquareWidth() {
  return inGameVectorPixels / getMazeWidth() * gameScaleFactor;
}

void p(x) {
  // ignore: prefer_interpolation_to_compose_strings
  debugPrint("///// A " + DateTime.now().toString() + " " + x.toString());
}

String endText(double value) {
  double x = percentile(scoreboardItems, value) * 100;
  String z = x.toStringAsFixed(0);
  String y =
      "\nTime: ${value.toStringAsFixed(1)} seconds \n\nRank: ${z}th %ile\n";
  return y;
}

double percentile(List<double> list, double value) {
  //p(["percentile", list.length]);
  List newList = [];
  for (int i = 0; i < list.length; i++) {
    newList.add(list[i]);
  }
  newList.add(value);
  newList.sort();
  return 1 - newList.indexOf(value) / newList.length;
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

int getRollSpinDirection(Vector2 vel, Vector2 gravity) {
  WallLocation onWall = WallLocation.bottom;
  bool clockwise = true;
  double small = 4;

  if (vel.x.abs() > small) {
    //moving left or right
    if (gravity.y > 0) {
      onWall = WallLocation.bottom;
    } else {
      onWall = WallLocation.top;
    }
  } else if (vel.y.abs() > small) {
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
