import 'dart:core';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/geometry.dart';

import '../../style/palette.dart';
import '../../utils/helper.dart';

const int kPacmanDeadResetTimeAnimationMillis = 1100;
const int pacmanCircleIncrements = 64;
const int pacmanMouthWidthDefault = pacmanCircleIncrements ~/ 4;
const int pacmanDeadIncrements = (pacmanCircleIncrements * 3) ~/ 4;
const int pacmanEatingHalfIncrements = (pacmanCircleIncrements * 1) ~/ 4;
final Paint pacmanPaint = Paint()..color = Palette.pacman.color;
const bool _loadFromFile = false;

class PacmanSprites {
  // ignore: unused_element
  Future<void> _savePictureAtFrac(int size, int mouthWidthAsInt) async {
    logGlobal("save picture");
    final Picture picture = _pacmanRecorderAtFrac(size, mouthWidthAsInt);
    final Image image = await picture.toImage(size, size);
    final ByteData? imageBytes = await image.toByteData(
      format: ImageByteFormat.png,
    );
    await File(
      'C:/tmp/$mouthWidthAsInt.png',
    ).writeAsBytes(imageBytes!.buffer.asUint8List());
  }

  Picture _pacmanRecorderAtFrac(int size, int mouthWidthAsInt) {
    double mouthWidth = mouthWidthAsInt / pacmanCircleIncrements;
    mouthWidth = mouthWidth.clamp(0, 1);
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Rect rect = Rect.fromCenter(
      center: Offset(size / 2, size / 2),
      width: size.toDouble(),
      height: size.toDouble(),
    );
    canvas.drawArc(
      rect,
      tau / 2 + tau * ((mouthWidth / 2) + 0.5),
      tau * (1 - mouthWidth),
      true,
      pacmanPaint,
    );
    final Picture picture = recorder.endRecording();
    return picture;
  }

  Future<Sprite> _pacmanAtFracReal(int size, int mouthWidthAsInt) async {
    if (_loadFromFile) {
      return Sprite(await Flame.images.load('$mouthWidthAsInt.png'));
    } else {
      return Sprite(
        await _pacmanRecorderAtFrac(size, mouthWidthAsInt).toImage(size, size),
      );
    }
  }

  final Map<int, Future<Sprite>> _pacmanSpriteAtFracCache =
      <int, Future<Sprite>>{};
  int? _pacmanSpriteCacheSize;

  Future<List<Sprite>> _lf2fl(List<Future<Sprite>> lf) async {
    //converts list of futures to a future of a list
    final List<Sprite> finalItems = <Sprite>[];
    for (final Future<Sprite> item in lf) {
      final Sprite finalItem = await item;
      finalItems.add(finalItem);
    }
    return finalItems;
  }

  Future<List<Sprite>> pacmanNormalSprites(int size) async {
    final List<Future<Sprite>> lf = List<Future<Sprite>>.generate(
      1,
      (int index) => _pacmanAtFrac(size, pacmanMouthWidthDefault),
    );
    return _lf2fl(lf);
  }

  Future<List<Sprite>> pacmanEatingSprites(int size) async {
    final List<Future<Sprite>> lf = List<Future<Sprite>>.generate(
      pacmanEatingHalfIncrements * 2, //open and close
      (int index) =>
          _pacmanAtFrac(size, (pacmanMouthWidthDefault - (index + 1)).abs()),
    );
    return _lf2fl(lf);
  }

  Future<List<Sprite>> pacmanDyingSprites(int size) async {
    final List<Future<Sprite>> lf = List<Future<Sprite>>.generate(
      pacmanDeadIncrements + 1, //open and close
      (int index) => _pacmanAtFrac(size, pacmanMouthWidthDefault + index),
    );
    return _lf2fl(lf);
  }

  Future<List<Sprite>> pacmanBirthingSprites(int size) async {
    final List<Future<Sprite>> lf = List<Future<Sprite>>.generate(
      pacmanDeadIncrements + 1, //open and close
      (int index) => _pacmanAtFrac(
        size,
        pacmanMouthWidthDefault + (pacmanDeadIncrements + 1 - index),
      ),
    );
    return _lf2fl(lf);
  }

  void _precacheAllPacmanAtFrac(int size) {
    if (_pacmanSpriteAtFracCache.isEmpty || _pacmanSpriteCacheSize != size) {
      //call first time, later times no effect
      _pacmanSpriteCacheSize = size;
      _pacmanSpriteAtFracCache.clear();
      for (int index = 0; index < pacmanCircleIncrements + 1; index++) {
        //_savePictureAtFrac(index);
        if (!_pacmanSpriteAtFracCache.keys.contains(index)) {
          //avoid redoing if done previously
          _pacmanSpriteAtFracCache[index] = _pacmanAtFracReal(size, index);
        }
      }
    }
  }

  Future<Sprite> _pacmanAtFrac(int size, int mouthWidth) async {
    _precacheAllPacmanAtFrac(size);
    mouthWidth = mouthWidth.clamp(0, pacmanCircleIncrements);
    return _pacmanSpriteAtFracCache[mouthWidth]!;
  }
}

PacmanSprites pacmanSprites = PacmanSprites();
