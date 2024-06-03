import 'package:flutter/foundation.dart';
import 'dart:core';

const String appTitle = "Pacman ROLL";
const bool mazeOn = true;
const bool maze1 = true;
final bool fbOn = !(windows && !kIsWeb);

final bool android = defaultTargetPlatform == TargetPlatform.android;
final bool iOS = defaultTargetPlatform == TargetPlatform.iOS;
final bool windows = defaultTargetPlatform == TargetPlatform.windows;
const bool web = kIsWeb;

const useForgePhysicsBallRotation = false;
const gameScaleFactor = maze1 ? 1.0 : 0.95;
const flameGameZoom = 30.0;
const double kSquareNotionalSize = 1700;

const double pelletScaleFactor = maze1 ? 0.4 : 0.46;

final soundOn = !(windows && !kIsWeb);
final bool sirenEnabled = iOS ? false : true;

const multipleSpawningPacmans = false;
const multipleSpawningGhosts = false;

const String chars =
    'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
