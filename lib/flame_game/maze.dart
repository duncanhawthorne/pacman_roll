import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import 'components/maze_wall.dart';
import 'components/mini_pellet.dart';
import 'components/super_pellet.dart';
import 'components/wrapper_no_events.dart';
import 'pacman_game.dart';

final List<String> mazeNames = ["A", "B", "C"];

class Maze {
  Maze({
    required mazeIdInitial,
  }) {
    setMazeIdReal(mazeIdInitial);
  }

  late final ValueNotifier<int> mazeIdNotifier = ValueNotifier(0);

  int get mazeId => mazeIdNotifier.value;

  set mazeId(int i) => setMazeIdReal(i);

  double mazeWidth = 0;
  double mazeHeight = 0;

  void setMazeIdReal(int i) {
    {
      mazeIdNotifier.value = i;
      ghostStart = _vectorOfMazeListCode(_kGhostStart);
      pacmanStart = _vectorOfMazeListCode(_kPacmanStart);
      cage = _vectorOfMazeListCode(_kCage);
      mazeWidth = blockWidth() * _mazeLayout[0].length;
      mazeHeight = blockWidth() * _mazeLayout.length;
    }
  }

  final List _decodedMazeList = [
    _decodeMazeLayout(_mazeP1Layout),
    _decodeMazeLayout(_mazeMP4Layout),
    _decodeMazeLayout(_mazeMP1Layout)
  ];

  get _mazeLayout => _decodedMazeList[mazeId];
  late Vector2 ghostStart = _vectorOfMazeListCode(_kGhostStart);
  late Vector2 pacmanStart = _vectorOfMazeListCode(_kPacmanStart);
  late Vector2 cage = _vectorOfMazeListCode(_kCage);

  static const bool _largeSprites = true;
  static const pelletScaleFactor = _largeSprites ? 0.4 : 0.46;

  Vector2 ghostStartForId(int idNum) {
    return ghostStart + Vector2(spriteWidth() * (idNum % 3 - 1), 0);
  }

  Vector2 ghostSpawnForId(int idNum) {
    return idNum <= 2 ? ghostStartForId(idNum) : cage;
  }

  int spriteWidthOnScreen(Vector2 size) {
    return (spriteWidth() /
            (kSquareNotionalSize / flameGameZoom) *
            min(size.x, size.y))
        .toInt();
  }

  double blockWidth() {
    return kSquareNotionalSize /
        flameGameZoom /
        max(_mazeLayoutHorizontalLength(), _mazeLayoutVerticalLength());
  }

  double spriteWidth() {
    return blockWidth() * (_largeSprites ? 2 : 1);
  }

  int _mazeLayoutHorizontalLength() {
    return _mazeLayout.isEmpty ? 0 : _mazeLayout[0].length;
  }

  int _mazeLayoutVerticalLength() {
    return _mazeLayout.isEmpty ? 0 : _mazeLayout.length;
  }

  bool _wallAt(int i, int j) {
    if (i >= _mazeLayout.length ||
        i < 0 ||
        j >= _mazeLayout[i].length ||
        j < 0) {
      return false;
    } else {
      return _mazeLayout[i][j] == _kWall;
    }
  }

  bool _circleAt(int i, int j) {
    assert(_wallAt(i, j));
    return !(_wallAt(i - 1, j) && _wallAt(i + 1, j) ||
        _wallAt(i, j - 1) && _wallAt(i, j + 1));
  }

  Vector2 _vectorOfMazeListIndex(int icore, int jcore,
      {double ioffset = 0, double joffset = 0}) {
    double i = ioffset + icore;
    double j = joffset + jcore;
    return Vector2(j + 1 / 2 - _mazeLayout[0].length / 2,
            i + 1 / 2 - _mazeLayout.length / 2) *
        blockWidth();
  }

  Vector2 _vectorOfMazeListCode(String code) {
    for (int i = 0; i < _mazeLayout.length; i++) {
      for (int j = 0; j < _mazeLayout[i].length; j++) {
        if (_mazeLayout[i][j] == code) {
          return _vectorOfMazeListIndex(i, j, ioffset: _largeSprites ? 0.5 : 0);
        }
      }
    }
    return Vector2(0, 0);
  }

  bool _pelletCodeAtCell(int i, int j) {
    return _mazeLayout[i][j] == _kMiniPellet ||
        _mazeLayout[i][j] == _kSuperPellet;
  }

  bool _pelletAt(int i, int j) {
    return i >= 0 &&
        j >= 0 &&
        i + 1 < _mazeLayout.length &&
        j + 1 < _mazeLayout[0].length &&
        _pelletCodeAtCell(i, j) &&
        _pelletCodeAtCell(i, j + 1) &&
        _pelletCodeAtCell(i + 1, j) &&
        _pelletCodeAtCell(i + 1, j + 1);
  }

  PelletWrapper pellets(
      ValueNotifier pelletsRemainingNotifier, bool superPelletsEnabled) {
    final result = PelletWrapper();
    //pelletsRemainingNotifier.value = 0;
    for (int i = 0; i < _mazeLayout.length; i++) {
      for (int j = 0; j < _mazeLayout[i].length; j++) {
        Vector2 center = _vectorOfMazeListIndex(i, j,
            ioffset: _largeSprites ? 1 / 2 : 0,
            joffset: _largeSprites ? 1 / 2 : 0);
        if (_pelletAt(i, j)) {
          if (_mazeLayout[i][j] == _kMiniPellet) {
            result.add(MiniPellet(position: center));
          }
          if (_mazeLayout[i][j] == _kSuperPellet) {
            if (superPelletsEnabled) {
              result.add(SuperPellet(position: center));
            } else {
              result.add(MiniPellet(position: center));
            }
          }
        }
      }
    }
    return result;
  }

  static const _mazeInnerWallWidthFactor = 0.7;
  static const double _pixelationBuffer = 0.03;
  WallWrapper mazeWalls() {
    final result = WallWrapper();
    double scale = blockWidth();
    for (int i = 0; i < _mazeLayout.length; i++) {
      for (int j = 0; j < _mazeLayout[i].length; j++) {
        Vector2 center = _vectorOfMazeListIndex(i, j);
        if (_wallAt(i, j)) {
          if (_circleAt(i, j)) {
            result.add(MazeWallCircleGround(center, scale / 2));
            result.add(MazeWallCircleVisual(
                position: center,
                radius: scale / 2 * _mazeInnerWallWidthFactor));
          }
          if (!_wallAt(i, j - 1)) {
            int k = 0;
            while (j + k < _mazeLayout[i].length && _wallAt(i, j + k + 1)) {
              k++;
            }
            if (k > 0) {
              result.add(MazeWallRectangleGround(
                  center + Vector2(scale * k / 2, 0),
                  scale * (k + _pixelationBuffer),
                  scale));
              result.add(MazeWallSquareVisual(
                  position: center + Vector2(scale * k / 2, 0),
                  width: scale * (k + _pixelationBuffer),
                  height: scale * _mazeInnerWallWidthFactor));
            }
          }

          if (!_wallAt(i - 1, j)) {
            int k = 0;
            while (i + k < _mazeLayout.length && _wallAt(i + k + 1, j)) {
              k++;
            }
            if (k > 0) {
              result.add(MazeWallRectangleGround(
                  center + Vector2(0, scale * k / 2),
                  scale,
                  scale * (k + _pixelationBuffer)));
              result.add(MazeWallSquareVisual(
                  position: center + Vector2(0, scale * k / 2),
                  width: scale * _mazeInnerWallWidthFactor,
                  height: scale * (k + _pixelationBuffer)));
            }
          }
          if ((!_wallAt(i - 1, j) || !_wallAt(i - 1, j + 1)) &&
              (!_wallAt(i, j - 1) || !_wallAt(i + 1, j - 1)) &&
              !_wallAt(i - 1, j - 1) &&
              _wallAt(i + 1, j) &&
              _wallAt(i, j + 1) &&
              _wallAt(i + 1, j + 1)) {
            //top left of a block
            int k = 0;
            while (j + k < _mazeLayout[i].length &&
                _wallAt(i + 1, j + k + 1) &&
                _wallAt(i, j + k + 1)) {
              k++;
            }
            int l = 0;
            while (i + l < _mazeLayout.length &&
                _wallAt(i + l + 1, j + 1) &&
                _wallAt(i + l + 1, j)) {
              l++;
            }
            if (k > 0 && l > 0) {
              result.add(MazeWallSquareVisual(
                  position: center + Vector2(scale * k / 2, scale * l / 2),
                  width: scale * k,
                  height: scale * l));
            }
          }
        }
      }
    }
    return result;
  }

  static const _kMiniPellet = "0"; //quad of dots
  static const _kWall = "1";

  // ignore: unused_field
  static const _kLair = "2";
  static const _kSuperPellet = "3"; //quad top
  // ignore: unused_field
  static const _kEmpty = "4";
  static const _kGhostStart = "7";
  static const _kPacmanStart = "8";
  static const _kCage = "9";

  static const _mazeP1Layout = [
    '11111111111111111111111111111',
    '10000000000000100000000000001',
    '10000000000000100000000000001',
    '13311100111100100111100111331',
    '10011100111100100111100111001',
    '10000000000000000000000000001',
    '10000000000000000000000000001',
    '10011100100111111100100111001',
    '10000000100000100000100000001',
    '10000000100000100000100000001',
    '11111100111144144111100111111',
    '44444100144444744444100144444',
    '44444100144444444444100144444',
    '11111100144111111144100111111',
    '44444400444122922144400444444',
    '44444400444122222144400444444',
    '11111100144111111144100111111',
    '44444100144444444444100144444',
    '44444100144444444444100144444',
    '11111100144111111144100111111',
    '10000000000000100000000000001',
    '10000000000000100000000000001',
    '13311100111100100111100111331',
    '10000100000000800000000100001',
    '10000100000000400000000100001',
    '11100100100111111100100100111',
    '10000000100000100000100000001',
    '10000000100000100000100000001',
    '10011111111100100111111111001',
    '10000000000000000000000000001',
    '10000000000000000000000000001',
    '11111111111111111111111111111'
  ];

  static const _mazeMP4Layout = [
    '11111111111111111111111111111',
    '10000000000000000000000000001',
    '10000000000000000000000000001',
    '10010011100111111100111001001',
    '13310011100100000100111001331',
    '10010000000100000100000001001',
    '10010000000100100100000001001',
    '10011100100100100100100111001',
    '10000000100000100000100000001',
    '10000000100000100000100000001',
    '11100111111144144111111100111',
    '44100000144444744444100000144',
    '11100000144444444444100000111',
    '00000100144111111144100100000',
    '00000100444122922144400100000',
    '11100100444122222144400100111',
    '00000100144111111144100100000',
    '00000100144444444444100100000',
    '11100000144444444444100000111',
    '44100000111144144111100000144',
    '44100100000000100000000100144',
    '44100100000000100000000100144',
    '11100111100100100100111100111',
    '10000000000100800100000000001',
    '10000000000100400100000000001',
    '10011100100111111100100111001',
    '13310000100000000000100001331',
    '10010000100000000000100001001',
    '10010011111100100111111001001',
    '10000000000000100000000000001',
    '10000000000000100000000000001',
    '11111111111111111111111111111'
  ];

  static const _mazeMP1Layout = [
    '11111111111111111111111111111',
    '10000000100000000000100000001',
    '13300000100000000000100000331',
    '10011100100111111100100111001',
    '10000000000000000000000000001',
    '10000000000000000000000000001',
    '11100100111100100111100100111',
    '11100100111100100111100100111',
    '44400100000000100000000100444',
    '44400100000000100000000100444',
    '11100111144111111144111100111',
    '44100000044444744444000000144',
    '44100000044444444444000000144',
    '44100111144111111144111100144',
    '44100100444122922144400100144',
    '44100100444122222144400100144',
    '11100100144111111144100100111',
    '44400000144444444444100000444',
    '44400000144444444444100000444',
    '11100111111144144111111100111',
    '44100000000000100000000000144',
    '44100000000000100000000000144',
    '11100111100111111100111100111',
    '10000000000000800000000000001',
    '10000000000000400000000000001',
    '10011100111100100111100111001',
    '13311100100000100000100111331',
    '10011100100000100000100111001',
    '10011100100111111100100111001',
    '10000000000000000000000000001',
    '10000000000000000000000000001',
    '11111111111111111111111111111'
  ];
}

List<List<String>> _decodeMazeLayout(encodedMazeLayout) {
  List<List<String>> result = [];
  for (String row in encodedMazeLayout) {
    List rowListString = row.split("");
    List<String> rowListInt = [];
    for (String letter in rowListString) {
      //rowListInt.add(int.parse(letter));
      rowListInt.add(letter);
    }
    result.add(rowListInt);
  }
  return result;
}

Maze maze = Maze(mazeIdInitial: 0);
