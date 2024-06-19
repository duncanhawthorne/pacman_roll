import 'dart:core';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../../utils/helper.dart';

const int pacmanRenderFracIncrementsNumber = 32;
const int pacmanMouthWidthDefault =
    pacmanRenderFracIncrementsNumber ~/ 4; //8 / 32; //5/32
const int pacmanDeadFrames = (pacmanRenderFracIncrementsNumber * 3) ~/
    4; //(kPacmanDeadResetTimeAnimationMillis / 33).ceil();
const int pacmanEatingHalfFrames = (pacmanRenderFracIncrementsNumber * 1) ~/
    4; //(kPacmanHalfEatingResetTimeMillis / 67).ceil();
final Paint yellowPacmanPaint = Paint()
  ..color = Colors.yellowAccent; //blue; //yellowAccent;
const loadFromFile = false;

class PacmanSprites {
  // ignore: unused_element
  void _savePictureAtFrac(int size, int mouthWidthAsInt) async {
    debug("save picture");
    Picture picture = _pacmanRecorderAtFrac(size, mouthWidthAsInt);
    final image = await picture.toImage(size, size);
    final imageBytes = await image.toByteData(format: ImageByteFormat.png);
    await File('C:/tmp/$mouthWidthAsInt.png')
        .writeAsBytes(imageBytes!.buffer.asUint8List());
  }

  Picture _pacmanRecorderAtFrac(int size, int mouthWidthAsInt) {
    double mouthWidth = mouthWidthAsInt / pacmanRenderFracIncrementsNumber;
    mouthWidth = max(0, min(1, mouthWidth));
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final Rect pacmanRect = Rect.fromCenter(
        center: Offset(size / 2, size / 2),
        width: size.toDouble(),
        height: size.toDouble());
    canvas.drawArc(pacmanRect, 2 * pi * ((mouthWidth / 2) + 0.5),
        2 * pi * (1 - mouthWidth), true, yellowPacmanPaint);
    Picture picture = recorder.endRecording();
    return picture;
  }

  Future<Sprite> _pacmanAtFracReal(int size, int mouthWidthAsInt) async {
    if (loadFromFile) {
      return Sprite(await Flame.images.load('dash/$mouthWidthAsInt.png'));
    } else {
      return Sprite(await _pacmanRecorderAtFrac(size, mouthWidthAsInt)
          .toImage(size, size));
    }
  }

  final Map<int, Future<Sprite>> _pacmanAtFracCache = {};
  int? _pacmanAtFracCacheSize;

  Future<List<Sprite>> _lf2fl(List<Future> lf) async {
    List<Sprite> finalItems = [];
    for (var item in lf) {
      Sprite finalItem = await item;
      finalItems.add(finalItem);
    }
    return finalItems;
  }

  Future<List<Sprite>> pacmanNormalSprites(int size) async {
    List<Future<Sprite>> lf = List<Future<Sprite>>.generate(
        1, (int index) => _pacmanAtFrac(size, pacmanMouthWidthDefault));
    return _lf2fl(lf);
  }

  Future<List<Sprite>> pacmanEatingSprites(int size) async {
    List<Future<Sprite>> lf = List<Future<Sprite>>.generate(
        pacmanEatingHalfFrames * 2, //open and close
        (int index) =>
            _pacmanAtFrac(size, (pacmanMouthWidthDefault - (index + 1)).abs()));
    return _lf2fl(lf);
  }

  Future<List<Sprite>> pacmanDyingSprites(int size) async {
    List<Future<Sprite>> lf = List<Future<Sprite>>.generate(
        pacmanDeadFrames + 1, //open and close
        (int index) => _pacmanAtFrac(size, pacmanMouthWidthDefault + index));
    return _lf2fl(lf);
  }

  Future<void> _precacheAllPacmanAtFrac(size) async {
    if (_pacmanAtFracCache.isEmpty || _pacmanAtFracCacheSize != size) {
      //call first time, later times no effect
      _pacmanAtFracCacheSize = size;
      _pacmanAtFracCache.clear();
      for (int index = 0;
          index < pacmanRenderFracIncrementsNumber + 1;
          index++) {
        //_savePictureAtFrac(index);
        if (!_pacmanAtFracCache.keys.contains(index)) {
          //avoid redoing if done previously
          _pacmanAtFracCache[index] = _pacmanAtFracReal(size, index);
        }
      }
    }
  }

  Future<Sprite> _pacmanAtFrac(int size, int fracInt) async {
    _precacheAllPacmanAtFrac(size); //call first time, later times no effect
    fracInt = max(0, min(pacmanRenderFracIncrementsNumber, fracInt));
    return await _pacmanAtFracCache[fracInt]!;
  }
}

PacmanSprites pacmanSprites = PacmanSprites();
