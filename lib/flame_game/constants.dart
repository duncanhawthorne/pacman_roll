import 'package:flutter/foundation.dart';
import 'maze_layout.dart';
import 'helper.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:core';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:ui';

const debugMode = false;
const bool mazeOn = true;

final bool android = defaultTargetPlatform == TargetPlatform.android;
final bool iOS = defaultTargetPlatform == TargetPlatform.iOS;
final bool windows = defaultTargetPlatform == TargetPlatform.windows;
const bool web = kIsWeb;
const mazeLayout = realMazeLayout;
const bool normaliseGravity = true; //android ? false : true;
const bool screenRotates = true; //android ? false : true;
const useGyro = !screenRotates;
final followCursor = windows;
final clickAndDrag = !windows && !useGyro;

const gameScaleFactor = screenRotates ? 0.9 : 1.0;
const flameGameZoom = 20.0;
const double kSquareNotionalSize = 1700;
double dx = 0;
double dy = 0;
const inGameVectorPixels = kSquareNotionalSize / flameGameZoom;

final Vector2 kGhostStartLocation = Vector2(0, -3) * getSingleSquareWidth();
final Vector2 kPacmanStartLocation = Vector2(0, 5) * getSingleSquareWidth();
final Vector2 kCageLocation = Vector2(0, -1) * getSingleSquareWidth();
final Vector2 kLeftPortalLocation = Vector2(-9, -1) * getSingleSquareWidth();
final Vector2 kRightPortalLocation = Vector2(9, -1) * getSingleSquareWidth();
final Vector2 kCompassLocation = Vector2(0, 0) * getSingleSquareWidth();
final Vector2 kOffScreenLocation = Vector2(0, 1000) * getSingleSquareWidth();
const double miniPelletAndSuperPelletScaleFactor = 0.46;
const pointerRotationSpeed = 10;
bool gameRunning = false;

const int kGhostResetTimeMillis = 1000;
const int kGhostChaseTimeMillis = 6000;
const int kPacmanDeadResetTimeMillis = 1000;
const int kPacmanHalfEatingResetTimeMillis = 180;

bool globalPhysicsLinked = true;
const bool rotateCamera = true;
const bool actuallyMoveSpritesToScreenPos = !rotateCamera;

final bool sirenOn = iOS ? false : true;
const bool pelletEatSoundOn = true; //iOS ? false : true;
const multiplePacmans = false;

// With the `TextPaint` we define what properties the text that we are going
// to render will have, like font family, size and color in this instance.
final textRenderer = TextPaint(
  style: const TextStyle(
    fontSize: 30,
    color: Colors.white,
    fontFamily: 'Press Start 2P',
  ),
);

const multiGhost = false;


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
  const mouthWidth = 5 / 32;
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

