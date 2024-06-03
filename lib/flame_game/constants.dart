import 'package:flutter/foundation.dart';
import 'dart:core';

const String appTitle = "Pacman ROLL";

//final bool android = defaultTargetPlatform == TargetPlatform.android;
final bool iOS = defaultTargetPlatform == TargetPlatform.iOS;
//final bool windows = defaultTargetPlatform == TargetPlatform.windows;

const useForgePhysicsBallRotation = false;
const flameGameZoom = 30.0; //determines speed of game
const double kSquareNotionalSize = 1700; //determines speed of game

const multipleSpawningPacmans = false;
const multipleSpawningGhosts = false;
