import 'components/pacman_sprites.dart';
import 'constants.dart';
import 'saves.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'dart:core';
//import 'package:sensors_plus/sensors_plus.dart';
import '../style/palette.dart';
import 'package:flutter/services.dart';

import 'title_fix_stub.dart' if (dart.library.js_interop) 'title_fix_web.dart';

final palette = Palette();

Save save = Save();
PacmanSprites pacmanSprites = PacmanSprites();

double blockWidth() {
  return inGameVectorPixels / mazeLayoutLength() * gameScaleFactor;
}

double spriteWidth() {
  return blockWidth() * (expandedMaze ? 2 : 1);
}

int mazeLayoutLength() {
  return wrappedMazeLayout.isEmpty ? 0 : wrappedMazeLayout[0].length;
}

void p(x) {
  debugPrint("///// A ${DateTime.now()} $x");
}

String getRandomString(random, int length) =>
    String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

/*
void legacyHandleAcceleratorEvents(PacmanWorld world) {
  if (useGyro) {
    accelerometerEventStream().listen(
      //start once and then runs
      (AccelerometerEvent event) {
        world.setGravity(
            Vector2(event.y, event.x - 5) * (android && web ? 5 : 1));
      },
      onError: (error) {
        // Logic to handle error
        // Needed for Android in case sensor is not available
      },
      cancelOnError: true,
    );
  }
}
 */

Vector2 sanitizeScreenSize(Vector2 size) {
  if (size.x > size.y) {
    return Vector2(kSquareNotionalSize * size.x / size.y, kSquareNotionalSize);
  } else {
    return Vector2(kSquareNotionalSize, kSquareNotionalSize * size.y / size.x);
  }
}

void setStatusBarColor(color) {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: color, // Status bar color
  ));
}

void fixTitle(Color color) {
  fixTitleReal(color); //either from web or stub
}

int roundUpToMult(int x, int roundUpMult) {
  return (x / roundUpMult).ceil() * roundUpMult;
}
