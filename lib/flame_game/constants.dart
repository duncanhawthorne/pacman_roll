import 'package:flutter/foundation.dart';
import 'dart:core';

const String appTitle = "Pacman ROLL";
final bool firebaseOn = !(windows && !kIsWeb);

final bool android = defaultTargetPlatform == TargetPlatform.android;
final bool iOS = defaultTargetPlatform == TargetPlatform.iOS;
final bool windows = defaultTargetPlatform == TargetPlatform.windows;
const bool web = kIsWeb;

const useForgePhysicsBallRotation = false;
const flameGameZoom = 30.0;
const double kSquareNotionalSize = 1700;

final soundOn = !(windows && !kIsWeb);
final bool sirenEnabled = iOS ? false : true;

const multipleSpawningPacmans = false;
const multipleSpawningGhosts = false;

const String chars =
    'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
