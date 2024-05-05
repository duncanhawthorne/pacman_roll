import 'package:flutter/foundation.dart';
//import '../audio/audio_controller.dart';
import 'maze_layout.dart';
import 'helper.dart';
import 'package:flame/components.dart';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:core';
import "dart:math";

import '../../audio/sounds.dart';
import 'package:audioplayers/audioplayers.dart';

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
//final dragBasedOnAngles = iOS;

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
bool startGameMusic = true;
const bool soundsOn = true;
const bool rotateCamera = true;
const bool actuallyMoveSpritesToScreenPos = !rotateCamera;

final bool sirenOn = iOS ? false : true;
const bool pelletEatSoundOn = true; //iOS ? false : true;
const multiplePacmans = false;
const centralisedAudio = true;

final textRenderer = TextPaint(
  style: const TextStyle(
    fontSize: 30,
    color: Colors.white,
    fontFamily: 'Press Start 2P',
  ),
);

final random = Random();

const multiGhost = false;
Map<SfxType, AudioPlayer> audioPlayerMap = {};

void stopAllAudio() {
  for (SfxType key in audioPlayerMap.keys) {
    stopSpecificAudio(key);
  }
}

void stopSpecificAudio(SfxType type) {
  if (audioPlayerMap.keys.contains(type)) {
    audioPlayerMap[type]!.stop();
    audioPlayerMap[type]!.release();
  }
}
