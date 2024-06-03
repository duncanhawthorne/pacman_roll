import 'dart:io';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'dart:core';
import 'dart:ui';
import '../helper.dart';

const int pacmanRenderFracIncrementsNumber = 32;
const int pacmanMouthWidthDefault =
    pacmanRenderFracIncrementsNumber ~/ 4; //8 / 32; //5/32
const int pacmanDeadFrames = (pacmanRenderFracIncrementsNumber * 3) ~/
    4; //(kPacmanDeadResetTimeAnimationMillis / 33).ceil();
const int pacmanEatingHalfFrames = (pacmanRenderFracIncrementsNumber * 1) ~/
    4; //(kPacmanHalfEatingResetTimeMillis / 67).ceil();
final Paint yellowPacmanPaint = Paint()
  ..color = Colors.yellowAccent; //blue; //yellowAccent;

class PacmanSprites {
  static const pacmanRectSize = 50;
  final Rect pacmanRect = Rect.fromCenter(
      center: const Offset(pacmanRectSize / 2, pacmanRectSize / 2),
      width: pacmanRectSize.toDouble(),
      height: pacmanRectSize.toDouble());

  // ignore: unused_element
  void _savePictureAtFrac(int mouthWidthAsInt) async {
    p("save picture");
    Picture picture = _pacmanRecorderAtFrac(mouthWidthAsInt);
    final image = await picture.toImage(pacmanRectSize, pacmanRectSize);
    final imageBytes = await image.toByteData(format: ImageByteFormat.png);
    await File('C:/tmp/$mouthWidthAsInt.png')
        .writeAsBytes(imageBytes!.buffer.asUint8List());
  }

  Picture _pacmanRecorderAtFrac(int mouthWidthAsInt) {
    double mouthWidth = mouthWidthAsInt / pacmanRenderFracIncrementsNumber;
    mouthWidth = max(0, min(1, mouthWidth));
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawArc(pacmanRect, 2 * pi * ((mouthWidth / 2) + 0.5),
        2 * pi * (1 - mouthWidth), true, yellowPacmanPaint);
    Picture picture = recorder.endRecording();
    return picture;
  }

  Future<Sprite> _pacmanAtFracReal(int mouthWidthAsInt) async {
    return Sprite(await Flame.images.load('dash/$mouthWidthAsInt.png'));
    //return Sprite(await _pacmanRecorderAtFrac(mouthWidthAsInt)
    //    .toImage(pacmanRectSize, pacmanRectSize));
  }

  final Map<int, Future<Sprite>> _pacmanAtFracCache = {};

  Future<List<Sprite>> lf2fl(List<Future> lf) async {
    //rolls from list of futures to future of a list

    List<Sprite> finalItems = [];

    /*
    // Get the item keys from the network
    List itemsKeysList = List<int>.generate(lf.length, (i) => i);

    // Future.wait will wait until I get an actual list back!
    await Future.wait(itemsKeysList.map((item) async {
      Sprite finalItem = await lf[item];
      finalItems.add(finalItem);
    }).toList());

     */

    for (var item in lf) {
      Sprite finalItem = await item;
      finalItems.add(finalItem);
    }

    return finalItems;
  }

  Future<List<Sprite>> pacmanEatingSprites() async {
    List<Future<Sprite>> lf = List<Future<Sprite>>.generate(
        pacmanEatingHalfFrames * 2, //open and close
        (int index) =>
            pacmanAtFrac((pacmanMouthWidthDefault - (index + 1)).abs()));
    return lf2fl(lf);
  }

  Future<List<Sprite>> pacmanDyingSprites() async {
    List<Future<Sprite>> lf = List<Future<Sprite>>.generate(
        pacmanDeadFrames + 1, //open and close
        (int index) => pacmanAtFrac(pacmanMouthWidthDefault + index));
    return lf2fl(lf);
  }

  Future<void> _precacheAllPacmanAtFrac() async {
    if (_pacmanAtFracCache.isEmpty) {
      //call first time, later times no effect
      for (int index = 0;
          index < pacmanRenderFracIncrementsNumber + 1;
          index++) {
        //_savePictureAtFrac(index);
        if (!_pacmanAtFracCache.keys.contains(index)) {
          //avoid redoing if done previously
          _pacmanAtFracCache[index] = _pacmanAtFracReal(index);
        }
      }
    }
  }

  Future<Sprite> pacmanAtFrac(int fracInt) async {
    pacmanSprites
        ._precacheAllPacmanAtFrac(); //call first time, later times no effect
    fracInt = max(0, min(pacmanRenderFracIncrementsNumber, fracInt));
    return await _pacmanAtFracCache[fracInt]!;
  }
}
