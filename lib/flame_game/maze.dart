import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import 'components/mini_pellet.dart';
import 'components/pellet.dart';
import 'components/super_pellet.dart';
import 'components/wall.dart';
import 'pacman_game.dart';

final List<String> mazeNames = ["A", "B", "C"];
const _bufferColumns = 2;

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
      mazeWidth = blockWidth() * (_mazeLayout[0].length - _bufferColumns);
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
    return _mazeLayout.isEmpty ? 0 : (_mazeLayout[0].length - _bufferColumns);
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

  List<Pellet> pellets(
      ValueNotifier pelletsRemainingNotifier, bool superPelletsEnabled) {
    final List<Pellet> result = [];
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

  List<Component> mazeWalls() {
    final List<Component> result = [];
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

  List<Component> mazeBlockingWalls() {
    final List<Component> result = [];
    double scale = blockWidth();
    /*
    for (int i = 0; i < _mazeLayout.length; i++) {
      if (!_wallAt(i, 0) &&
          !_wallAt(i, _mazeLayout[i].length - 1) &&
          !_wallAt(i + 1, 0) &&
          !_wallAt(i + 1, _mazeLayout[i].length - 1)) {
        Vector2 centerLeft = _vectorOfMazeListIndex(i, 0);
        Vector2 centerRight =
            _vectorOfMazeListIndex(i, _mazeLayout[i].length - 1);
        result.add(
          MazeWallSquareVisualBlocking(
              position: centerLeft + Vector2(-1.5, 0.5) * scale,
              width: scale * 3,
              height: scale * (2 + _pixelationBuffer)),
        );
        result.add(
          MazeWallSquareVisualBlocking(
              position: centerRight + Vector2(1.5, 0.5) * scale,
              width: scale * 3,
              height: scale * (2 + _pixelationBuffer)),
        );
      }
    }
     */
    int width = 7;
    result.add(
      MazeWallSquareVisualBlocking(
          position: Vector2(
              scale * (_mazeLayoutHorizontalLength() / 2 + width / 2), 0),
          width: scale * width,
          height: scale * _mazeLayoutVerticalLength()),
    );
    result.add(
      MazeWallSquareVisualBlocking(
          position: Vector2(
              -scale * (_mazeLayoutHorizontalLength() / 2 + width / 2), 0),
          width: scale * width,
          height: scale * _mazeLayoutVerticalLength()),
    );
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
    '4111111111111111111111111111114',
    '4100000000000001000000000000014',
    '4100000000000001000000000000014',
    '4133111001111001001111001113314',
    '4100111001111001001111001110014',
    '4100000000000000000000000000014',
    '4100000000000000000000000000014',
    '4100111001001111111001001110014',
    '4100000001000001000001000000014',
    '4100000001000001000001000000014',
    '4111111001111441441111001111114',
    '4444441001444447444441001444444',
    '4444441001444444444441001444444',
    '1111111001441111111441001111111',
    '4444444004441229221444004444444',
    '4444444004441222221444004444444',
    '1111111001441111111441001111111',
    '4444441001444444444441001444444',
    '4444441001444444444441001444444',
    '4111111001441111111441001111114',
    '4100000000000001000000000000014',
    '4100000000000001000000000000014',
    '4133111001111001001111001113314',
    '4100001000000008000000001000014',
    '4100001000000004000000001000014',
    '4111001001001111111001001001114',
    '4100000001000001000001000000014',
    '4100000001000001000001000000014',
    '4100111111111001001111111110014',
    '4100000000000000000000000000014',
    '4100000000000000000000000000014',
    '4111111111111111111111111111114'
  ];

  static const _mazeMP4Layout = [
    '4111111111111111111111111111114',
    '4100000000000000000000000000014',
    '4100000000000000000000000000014',
    '4100100111001111111001110010014',
    '4133100111001000001001110013314',
    '4100100000001000001000000010014',
    '4100100000001001001000000010014',
    '4100111001001001001001001110014',
    '4100000001000001000001000000014',
    '4100000001000001000001000000014',
    '4111001111111441441111111001114',
    '4441000001444447444441000001444',
    '4111000001444444444441000001114',
    '4000001001441111111441001000004',
    '4000001004441229221444001000004',
    '4111001004441222221444001001114',
    '4000001001441111111441001000004',
    '4000001001444444444441001000004',
    '4111000001444444444441000001114',
    '4441000001111441441111000001444',
    '4441001000000001000000001001444',
    '4441001000000001000000001001444',
    '4111001111001001001001111001114',
    '4100000000001008001000000000014',
    '4100000000001004001000000000014',
    '4100111001001111111001001110014',
    '4133100001000000000001000013314',
    '4100100001000000000001000010014',
    '4100100111111001001111110010014',
    '4100000000000001000000000000014',
    '4100000000000001000000000000014',
    '4111111111111111111111111111114'
  ];

  static const _mazeMP1Layout = [
    '4111111111111111111111111111114',
    '4100000001000000000001000000014',
    '4133000001000000000001000003314',
    '4100111001001111111001001110014',
    '4100000000000000000000000000014',
    '4100000000000000000000000000014',
    '4111001001111001001111001001114',
    '1111001001111001001111001001111',
    '4444001000000001000000001004444',
    '4444001000000001000000001004444',
    '1111001111441111111441111001111',
    '4441000000444447444440000001444',
    '4441000000444444444440000001444',
    '4441001111441111111441111001444',
    '4441001004441229221444001001444',
    '4441001004441222221444001001444',
    '1111001001441111111441001001111',
    '4444000001444444444441000004444',
    '4444000001444444444441000004444',
    '1111001111111441441111111001111',
    '4441000000000001000000000001444',
    '4441000000000001000000000001444',
    '4111001111001111111001111001114',
    '4100000000000008000000000000014',
    '4100000000000004000000000000014',
    '4100111001111001001111001110014',
    '4133111001000001000001001113314',
    '4100111001000001000001001110014',
    '4100111001001111111001001110014',
    '4100000000000000000000000000014',
    '4100000000000000000000000000014',
    '4111111111111111111111111111114'
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
