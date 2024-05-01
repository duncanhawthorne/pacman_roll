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
final bool normaliseGravity = android ? false : true;
final bool screenRotates = android ? false : true;
final useGyro = !screenRotates;
final followCursor = windows;
final clickAndDrag = !windows && !useGyro;
final gameScaleFactor = screenRotates ? 0.9 : 1.0;

//AudioController? globalAudioController; //initial value which immediately gets overridden
double ksizex = 1700;
double ksizey = 1700;

//final double ksingleSquareWidthProxy = 4.0 * gameScaleFactor; //FIXME harcoded, right now approx value of getSingleSquareWidth()
final Vector2 kGhostStartLocation = Vector2(0, -3 * getSingleSquareWidth());
final Vector2 kPacmanStartLocation = Vector2(0, 5 * getSingleSquareWidth());
final Vector2 kCageLocation = Vector2(0, -1 * getSingleSquareWidth());
final Vector2 kLeftPortalLocation = Vector2(-9 * getSingleSquareWidth(), -1 * getSingleSquareWidth());
final Vector2 kRightPortalLocation = Vector2(9 * getSingleSquareWidth(), -1 * getSingleSquareWidth());

const int kGhostResetTimeMillis = 1000;
const int kGhostChaseTimeMillis = 6000;
const int kPacmanDeadResetTimeMillis = 1000;
const int kPacmanHalfEatingResetTimeMillis = 130;

bool globalPhysicsLinked = true;
bool gravityTurnedOn = false;
bool startGameMusic =
    false; //FIXME need to detect is settings have turned sound off, else slow down game when no sound playing