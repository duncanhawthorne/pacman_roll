import 'dart:math';
import 'package:flame/components.dart';
import 'dart:core';
import 'dart:ui';
import '../constants.dart';

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
  return Sprite(await _pacmanRecorderAtFrac(mouthWidthAsInt)
      .toImage(pacmanRectSize, pacmanRectSize));
}

Map<int, Future<Sprite>> _pacmanAtFracCache = {};

Future<List<Sprite>> lf2fl(List<Future> lf) async {
  //rolls from list of futures to future of a list

  List<Sprite> finalItems = [];
  // Get the item keys from the network
  List itemsKeysList =  List<int>.generate(lf.length, (i) => i);

  // Future.wait will wait until I get an actual list back!
  await Future.wait(itemsKeysList.map((item) async {
    Sprite finalItem = await lf[item];
    finalItems.add(finalItem);
  }).toList());

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
          (int index) =>
          pacmanAtFrac(pacmanMouthWidthDefault + index));
  return lf2fl(lf);
}


Future<void> precachePacmanAtFrac() async {
  for (int index = 0; index < pacmanRenderFracIncrementsNumber + 1; index++) {
    if (!_pacmanAtFracCache.keys.contains(index)) {
      //avoid redoing if done previously
      _pacmanAtFracCache[index] = _pacmanAtFracReal(index);
    }
  }
}

Future<Sprite> pacmanAtFrac(int fracInt) async {
  fracInt = max(0, min(pacmanRenderFracIncrementsNumber, fracInt));
  return await _pacmanAtFracCache[fracInt]!;
}