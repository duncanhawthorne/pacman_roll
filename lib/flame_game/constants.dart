import 'package:flutter/foundation.dart';
import '../audio/audio_controller.dart';
import 'maze_layout.dart';
import 'package:flame/components.dart';
import 'dart:math';

const debugMode = false;
const bool mazeOn = true;
const flameGameZoom = 20.0;
final bool android = defaultTargetPlatform == TargetPlatform.android;
const mazeLayout = realMazeLayout;
const bool normaliseGravity = true;
const bool screenRotates = true;

AudioController? globalAudioController; //initial value which immediately gets overridden
double ksizex = 1700;
double ksizey = 1700;
Vector2 globalGravity = Vector2(0, 0); //initial value which immediately gets overridden
double transAngle = 0; //2 * pi / 8;

const double ksingleSquareWidthProxy = 4.0; //FIXME harcoded, right now approx value of getSingleSquareWidth()
final Vector2 kGhostStartLocation = Vector2(0, -3 * ksingleSquareWidthProxy);
final Vector2 kPacmanStartLocation = Vector2(0, 5 * ksingleSquareWidthProxy);
final Vector2 kCageLocation = Vector2(0, -2 * ksingleSquareWidthProxy);
final Vector2 kLeftPortalLocation = Vector2(-9 * ksingleSquareWidthProxy, -1 * ksingleSquareWidthProxy);
final Vector2 kRightPortalLocation = Vector2(9 * ksingleSquareWidthProxy, -1 * ksingleSquareWidthProxy);

const int kGhostResetTimeMillis = 1000;
const int kGhostChaseTimeMillis = 10000;
const int kPacmanDeadResetTimeMillis = 1000;
const int kPacmanHalfEatingResetTimeMillis = 130;

bool globalPhysicsLinked = true;
bool gravityTurnedOn = false;
bool startGameMusic =
    false; //FIXME need to detect is settings have turned sound off, else slow down game when no sound playing