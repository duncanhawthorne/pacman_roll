import 'package:flutter/foundation.dart';
import 'helper.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';

const String appTitle = "Pacman ROLL";
const debugMode = false;
const bool mazeOn = true;

final bool android = defaultTargetPlatform == TargetPlatform.android;
final bool iOS = defaultTargetPlatform == TargetPlatform.iOS;
final bool windows = defaultTargetPlatform == TargetPlatform.windows;
const bool web = kIsWeb;
final isiOSMobile = kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
//const bool usePacmanImageFromDisk = false; //kIsWeb;
//const newPacmanDeathAnimation = true;

const useForgePhysicsBallRotation = false;
const bool normaliseGravity = true; //android ? false : true;
const bool screenRotates = true; //android ? false : true;
const useGyro = !screenRotates;
const followCursor = false; //windows;
const clickAndDrag = true; //!windows && !useGyro;

const gameScaleFactor = screenRotates ? 0.95 : 1.0;
const flameGameZoom = 30.0;
const double kSquareNotionalSize = 1700;
const inGameVectorPixels = kSquareNotionalSize / flameGameZoom;

final Vector2 kGhostStartLocation = Vector2(0, -3) * spriteWidth();
final Vector2 kPacmanStartLocation = Vector2(0, 5) * spriteWidth();
final Vector2 kCageLocation = Vector2(0, -1) * spriteWidth();
final Vector2 kLeftPortalLocation = Vector2(-(getMazeIntWidth() - 1) / 2 * 0.99, -1) * getSingleSquareWidth();
final Vector2 kRightPortalLocation = Vector2((getMazeIntWidth() - 1) / 2 * 0.99, -1) * getSingleSquareWidth();
final Vector2 kCompassLocation = Vector2(0, 0) * spriteWidth();
final Vector2 kOffScreenLocation = Vector2(0, 1000) * spriteWidth();
const double miniPelletAndSuperPelletScaleFactor = 0.46;
const pointerRotationSpeed = 10;
bool gameRunning = false;

const int kGhostResetTimeMillis = 1000;
const int kGhostChaseTimeMillis = 6000;
const int kPacmanDeadResetTimeMillis = 1700;
const int kPacmanDeadResetTimeAnimationMillis = 1250;
const int kPacmanHalfEatingResetTimeMillis = 180;
final int pacmanDeadFrames = (kPacmanDeadResetTimeAnimationMillis / 33).ceil();
final int pacmanEatingHalfFrames = (kPacmanHalfEatingResetTimeMillis / 67).ceil();

bool globalPhysicsLinked = true;
//const bool rotateCamera = true;
//const bool actuallyMoveSpritesToScreenPos = !rotateCamera;
const double pacmanMouthWidthDefault = 8 / 32; //5/32

final soundOn = !(windows && !kIsWeb);
final bool sirenEnabled = iOS ? false : true;
const bool pelletEatSoundOn = true; //iOS ? false : true;
const multipleSpawningPacmans = false;
const multipleSpawningGhosts = false;

bool fbOn = !(windows && !kIsWeb);
//String userName = "ABC";
FirebaseFirestore? db = fbOn ? FirebaseFirestore.instance : null;
List<double> scoreboardItemsDoubles = [];

const String chars =
    'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

// 0 - pac-dots
// 1 - wall
// 2 - ghost-lair
// 3 - power-pellet
// 4 - empty
// 5 - outside

/*
//final flatMazeLayout = flatten(wrappedMazeLayout);
List<T> flatten<T>(Iterable<Iterable<T>> list) =>
    [for (var sublist in list) ...sublist];
 */

const bool expandedMaze = false;
const wrappedMazeLayout = expandedMaze ? wrappedMazeLayoutExp : wrappedMazeLayoutNormal;

const wrappedMazeLayoutNormal = [
  [5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5],
  [5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5],
  [5, 1, 3, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 3, 1, 5],
  [5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5],
  [5, 1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 5],
  [5, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 5],
  [5, 1, 1, 1, 1, 0, 1, 1, 1, 4, 1, 4, 1, 1, 1, 0, 1, 1, 1, 1, 5],
  [5, 5, 5, 5, 1, 0, 1, 4, 4, 4, 4, 4, 4, 4, 1, 0, 1, 5, 5, 5, 5],
  [1, 1, 1, 1, 1, 0, 1, 4, 1, 1, 1, 1, 1, 4, 1, 0, 1, 1, 1, 1, 1],
  [4, 4, 4, 4, 4, 0, 4, 4, 1, 2, 2, 2, 1, 4, 4, 0, 4, 4, 4, 4, 4],
  [1, 1, 1, 1, 1, 0, 1, 4, 1, 1, 1, 1, 1, 4, 1, 0, 1, 1, 1, 1, 1],
  [5, 5, 5, 5, 1, 0, 1, 4, 4, 4, 4, 4, 4, 4, 1, 0, 1, 5, 5, 5, 5],
  [5, 1, 1, 1, 1, 0, 1, 4, 1, 1, 1, 1, 1, 4, 1, 0, 1, 1, 1, 1, 5],
  [5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5],
  [5, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 5],
  [5, 1, 3, 0, 1, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 1, 0, 3, 1, 5],
  [5, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 5],
  [5, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 5],
  [5, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 5],
  [5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5],
  [5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5]
];


const wrappedMazeLayoutExp = [[5, 5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5, 5],
[5, 5, 1, 0, 4, 0, 0, 0, 4, 0, 4, 0, 0, 4, 0, 1, 0, 4, 0, 0, 4, 0, 4, 0, 0, 0, 4, 0, 1, 5, 5],
[5, 5, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 1, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 5, 5],
[5, 5, 1, 3, 4, 1, 1, 0, 4, 1, 1, 1, 1, 4, 0, 1, 0, 4, 1, 1, 1, 1, 4, 0, 1, 1, 4, 3, 1, 5, 5],
[5, 5, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 5, 5],
[5, 5, 1, 0, 4, 0, 0, 0, 4, 0, 4, 0, 0, 4, 0, 0, 0, 4, 0, 0, 4, 0, 4, 0, 0, 0, 4, 0, 1, 5, 5],
[5, 5, 1, 0, 4, 1, 1, 0, 4, 1, 4, 0, 1, 1, 1, 1, 1, 1, 1, 0, 4, 1, 4, 0, 1, 1, 4, 0, 1, 5, 5],
[5, 5, 1, 4, 4, 4, 4, 4, 4, 1, 4, 4, 4, 4, 4, 1, 4, 4, 4, 4, 4, 1, 4, 4, 4, 4, 4, 4, 1, 5, 5],
[5, 5, 1, 0, 4, 0, 0, 0, 4, 1, 4, 0, 0, 4, 0, 1, 0, 4, 0, 0, 4, 1, 4, 0, 0, 0, 4, 0, 1, 5, 5],
[5, 5, 1, 1, 1, 1, 1, 0, 4, 1, 1, 1, 1, 4, 4, 1, 4, 4, 1, 1, 1, 1, 4, 0, 1, 1, 1, 1, 1, 5, 5],
[5, 5, 5, 5, 5, 5, 1, 0, 4, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 4, 0, 1, 5, 5, 5, 5, 5, 5],
[5, 5, 5, 5, 5, 5, 1, 0, 4, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 4, 0, 1, 5, 5, 5, 5, 5, 5],
[1, 1, 1, 1, 1, 1, 1, 0, 4, 1, 4, 4, 1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 4, 0, 1, 1, 1, 1, 1, 1, 1],
[4, 4, 4, 4, 4, 4, 4, 0, 4, 4, 4, 4, 1, 2, 2, 2, 2, 2, 1, 4, 4, 4, 4, 0, 4, 4, 4, 4, 4, 4, 4],
[4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 2, 2, 2, 2, 2, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4],
[1, 1, 1, 1, 1, 1, 1, 0, 4, 1, 4, 4, 1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 4, 0, 1, 1, 1, 1, 1, 1, 1],
[5, 5, 5, 5, 5, 5, 1, 0, 4, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 4, 0, 1, 5, 5, 5, 5, 5, 5],
[5, 5, 5, 5, 5, 5, 1, 4, 4, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 4, 4, 1, 5, 5, 5, 5, 5, 5],
[5, 5, 1, 1, 1, 1, 1, 0, 4, 1, 4, 4, 1, 1, 1, 1, 1, 1, 1, 4, 4, 1, 4, 0, 1, 1, 1, 1, 1, 5, 5],
[5, 5, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 5, 5],
[5, 5, 1, 0, 4, 0, 0, 0, 4, 0, 4, 0, 0, 4, 0, 1, 0, 4, 0, 0, 4, 0, 4, 0, 0, 0, 4, 0, 1, 5, 5],
[5, 5, 1, 0, 4, 1, 1, 0, 4, 1, 1, 1, 1, 4, 0, 1, 0, 4, 1, 1, 1, 1, 4, 0, 1, 1, 4, 0, 1, 5, 5],
[5, 5, 1, 3, 4, 0, 1, 0, 4, 0, 4, 0, 0, 4, 0, 4, 0, 4, 0, 0, 4, 0, 4, 0, 1, 0, 4, 3, 1, 5, 5],
[5, 5, 1, 4, 4, 4, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 4, 4, 4, 1, 5, 5],
[5, 5, 1, 1, 4, 0, 1, 0, 4, 1, 4, 0, 1, 1, 1, 1, 1, 1, 1, 0, 4, 1, 4, 0, 1, 0, 4, 1, 1, 5, 5],
[5, 5, 1, 4, 4, 4, 4, 4, 4, 1, 4, 4, 4, 4, 4, 1, 4, 4, 4, 4, 4, 1, 4, 4, 4, 4, 4, 4, 1, 5, 5],
[5, 5, 1, 0, 4, 0, 0, 0, 4, 1, 4, 0, 0, 4, 0, 1, 0, 4, 0, 0, 4, 1, 4, 0, 0, 0, 4, 0, 1, 5, 5],
[5, 5, 1, 0, 4, 1, 1, 1, 1, 1, 1, 1, 1, 4, 0, 1, 0, 4, 1, 1, 1, 1, 1, 1, 1, 1, 4, 0, 1, 5, 5],
[5, 5, 1, 0, 4, 0, 0, 0, 4, 0, 4, 0, 0, 4, 0, 0, 0, 4, 0, 0, 4, 0, 4, 0, 0, 0, 4, 0, 1, 5, 5],
[5, 5, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 5, 5],
[5, 5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5, 5]];