import 'package:flutter/foundation.dart';
//import '../audio/audio_controller.dart';
import 'maze_layout.dart';
import 'helper.dart';
import 'package:flame/components.dart';

const debugMode = false;
const bool mazeOn = true;
const flameGameZoom = 20.0;
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

//double ksizex = 1700;
//double ksizey = 1700;//2800; //1700;
const double kSquareNotionalSize = 1700;

double dx = 0;
double dy = 0;

final Vector2 kGhostStartLocation = Vector2(0, -3) * getSingleSquareWidth();
final Vector2 kPacmanStartLocation = Vector2(0, 5) * getSingleSquareWidth();
final Vector2 kCageLocation = Vector2(0, -1) * getSingleSquareWidth();
final Vector2 kLeftPortalLocation = Vector2(-9, -1) * getSingleSquareWidth();
final Vector2 kRightPortalLocation = Vector2(9, -1) * getSingleSquareWidth();
final Vector2 kCompassLocation = Vector2(0, 0) * getSingleSquareWidth();
final Vector2 kOffScreenLocation = Vector2(0, 1000) * getSingleSquareWidth();
const double miniPelletAndSuperPelletScaleFactor = 0.46;
const pointerRotationSpeed = 8;


const int kGhostResetTimeMillis = 1000;
const int kGhostChaseTimeMillis = 6000;
const int kPacmanDeadResetTimeMillis = 1000;
const int kPacmanHalfEatingResetTimeMillis = 150;

bool globalPhysicsLinked = true;
//bool gravityTurnedOn = true;
bool startGameMusic = true;
const bool soundsOn = true;
const bool actuallyRotateSprites = false;
//final spriteRotationFudgeFactor = actuallyRotateSprites ? kSquareNotionalSize / 80 : 1; //FIXME shouldn't be necessary
final spriteRotationFudgerFactor =  80 / 1700 * kSquareNotionalSize;

//double sirenVolume = 0;
const bool sirenOn = true; //iOS ? false : true;