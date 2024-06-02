import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'helper.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'dart:core';

const String appTitle = "Pacman ROLL";
//const debugMode = false;
const bool mazeOn = true;
const bool expandedMaze = true;

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
//const useGyro = !screenRotates;
const followCursor = false; //windows;
const clickAndDrag = true; //!windows && !useGyro;

const gameScaleFactor = !screenRotates ? 1.0 : (expandedMaze ? 1.0 : 0.95);
const flameGameZoom = 30.0;
const double kSquareNotionalSize = 1700;
const inGameVectorPixels = kSquareNotionalSize / flameGameZoom;

final Vector2 kGhostStartLocation =
    Vector2(0, expandedMaze ? -1.75 : -3) * spriteWidth();
final Vector2 kPacmanStartLocation =
    Vector2(0, expandedMaze ? 4.25 : 5) * spriteWidth();
final Vector2 kCageLocation = Vector2(0, -1) * spriteWidth();
final Vector2 kLeftPortalLocation =
    Vector2(-(mazeLayoutLength() - 1) / 2 * 0.99, expandedMaze ? -0.25 : -1) *
        blockWidth();
final Vector2 kRightPortalLocation =
    Vector2((mazeLayoutLength() - 1) / 2 * 0.99, expandedMaze ? -0.25 : -1) *
        blockWidth();
final Vector2 kCompassLocation = Vector2(0, 0) * spriteWidth();
final Vector2 kOffScreenLocation = Vector2(0, 1000) * spriteWidth();
const double pelletScaleFactor = expandedMaze ? 0.4 : 0.46;
const pointerRotationSpeed = 10;

const int kGhostResetTimeMillis = 1000;
const int kGhostChaseTimeMillis = 6000;
const int kPacmanDeadResetTimeMillis = 1700;
const int kPacmanDeadResetTimeAnimationMillis = 1250;
const int kPacmanHalfEatingResetTimeMillis = 180;
const int pacmanRenderFracIncrementsNumber = 32;
const int pacmanMouthWidthDefault =
    pacmanRenderFracIncrementsNumber ~/ 4; //8 / 32; //5/32
const int pacmanDeadFrames = (pacmanRenderFracIncrementsNumber * 3) ~/
    4; //(kPacmanDeadResetTimeAnimationMillis / 33).ceil();
const int pacmanEatingHalfFrames = (pacmanRenderFracIncrementsNumber * 1) ~/
    4; //(kPacmanHalfEatingResetTimeMillis / 67).ceil();

//const bool rotateCamera = true;
//const bool actuallyMoveSpritesToScreenPos = !rotateCamera;

final soundOn = !(windows && !kIsWeb);
final bool sirenEnabled = iOS ? false : true;
//const bool pelletEatSoundOn = true; //iOS ? false : true;
const multipleSpawningPacmans = false;
const multipleSpawningGhosts = false;

final bool fbOn = !(windows && !kIsWeb);
const String mainDB = "scores";
const String summaryDB = "summary";
//String userName = "ABC";

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
final Paint yellowPacmanPaint = Paint()
  ..color = Colors.yellowAccent; //blue; //yellowAccent;
final Paint blackBackgroundPaint = Paint()
  ..color = palette.flameGameBackground.color;
final Paint transparentPaint = Paint()..color = const Color(0x00000000);

const black = Color(0xff000000);
const lightBluePMR = Color(0xffa2fff3);

const pacmanRectSize = 50;
final Rect pacmanRect = Rect.fromCenter(
    center: const Offset(pacmanRectSize / 2, pacmanRectSize / 2),
    width: pacmanRectSize.toDouble(),
    height: pacmanRectSize.toDouble());

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

final wrappedMazeLayout = expandedMaze
    ? decodeMazeLayout(wrappedMazeLayoutExp)
    : wrappedMazeLayoutNormal;

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

const wrappedMazeLayoutExp = [
  '555555555555555555555555555555555',
  '551111111111111111111111111111155',
  '551000000000000610000000000006155',
  '551066660666660610666660666606155',
  '551361110611110410611110611136155',
  '551061110611110410611110611106155',
  '551000000000000000000000000006155',
  '551066660660666646660660666606155',
  '551061110610411111110610611106155',
  '551000000610000610000610000006155',
  '551666660616644614646610666666155',
  '551111110611114414411110611111155',
  '555555510614444444444410615555555',
  '555555510614444444444410615555555',
  '111111110614411111114410611111111',
  '444444440644412222214440644444444',
  '444444440644412222214440644444444',
  '111111110614411111114410611111111',
  '555555510614444444444410615555555',
  '555555510614444444444410615555555',
  '551111110614411111114410611111155',
  '551000000000000610000000000006155',
  '551066660666660610666660666606155',
  '551341110611110410611110611136155',
  '551000410000000440000000610006155',
  '551640410660666646660660610466155',
  '551110410610411111110610610411155',
  '551000000610000610000610000006155',
  '551066666616640610646616666606155',
  '551041111111110410611111111106155',
  '551000000000000000000000000006155',
  '551666666666666646666666666666155',
  '551111111111111111111111111111155'
];
