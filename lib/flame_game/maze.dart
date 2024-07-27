import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import 'components/maze_wall.dart';
import 'components/mini_pellet.dart';
import 'components/super_pellet.dart';
import 'components/wrapper_no_events.dart';
import 'pacman_game.dart';

class Maze {
  final ValueNotifier<int> mazeIdNotifier = ValueNotifier(0);

  int get mazeId => mazeIdNotifier.value;

  set mazeId(int i) => setMazeIdReal(i);

  void setMazeIdReal(int i) {
    {
      mazeIdNotifier.value = i;
      ghostStart = _vectorOfMazeListTargetNumber(7);
      pacmanStart = _vectorOfMazeListTargetNumber(8);
      cage = _vectorOfMazeListTargetNumber(9);
    }
  }

  final List _decodedMazeList = [
    _decodeMazeLayout(_mazeP1Layout),
    _decodeMazeLayout(_mazeMP4Layout),
    _decodeMazeLayout(_mazeMP1Layout)
  ];

  get _mazeLayout => _decodedMazeList[mazeId];
  late Vector2 ghostStart = _vectorOfMazeListTargetNumber(7);
  late Vector2 pacmanStart = _vectorOfMazeListTargetNumber(8);
  late Vector2 cage = _vectorOfMazeListTargetNumber(9);

  static const bool _largeSprites =
      true; //_chosenMaze != _smallSpritesMazeXLayout;
  static const pelletScaleFactor = _largeSprites ? 0.4 : 0.46;

  Vector2 ghostStartForId(int idNum) {
    return (idNum == 100 ? cage : ghostStart) +
        Vector2(spriteWidth() * (idNum <= 2 ? (idNum - 1) : 0), 0);
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

  double mazeWidth() {
    return blockWidth() * _mazeLayout[0].length;
  }

  double mazeHeight() {
    return blockWidth() * _mazeLayout.length;
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
      return _mazeLayout[i][j] == 1;
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

  Vector2 _vectorOfMazeListTargetNumber(int targetNumber) {
    for (int i = 0; i < _mazeLayout.length; i++) {
      for (int j = 0; j < _mazeLayout[i].length; j++) {
        if (_mazeLayout[i][j] == targetNumber) {
          return _vectorOfMazeListIndex(i, j, ioffset: _largeSprites ? 0.5 : 0);
        }
      }
    }
    return Vector2(0, 0);
  }

  bool _pelletCodeAtCell(int i, int j) {
    return _mazeLayout[i][j] == 0 || _mazeLayout[i][j] == 3;
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
          if (_mazeLayout[i][j] == 0) {
            result.add(MiniPelletCircle(position: center));
          }
          if (_mazeLayout[i][j] == 3) {
            if (superPelletsEnabled) {
              result.add(SuperPelletCircle(position: center));
            } else {
              result.add(MiniPelletCircle(position: center));
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
          if (!_wallAt(i - 1, j) &&
              !_wallAt(i, j - 1) &&
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

// 0 - pac-dots quad
// 1 - wall
// 2 - ghost-lair
// 3 - power-pellet quad top
// 4 - empty
// 7 - ghostStart
// 8 - pacmanStart
// 9 - cage

  // ignore: unused_field
  static const _mazeP1Layout = [
    '441111111111111111111111111111144',
    '441000000000000010000000000000144',
    '441000000000000010000000000000144',
    '441331110011110010011110011133144',
    '441001110011110010011110011100144',
    '441000000000000000000000000000144',
    '441000000000000000000000000000144',
    '441001110010011111110010011100144',
    '441000000010000010000010000000144',
    '441000000010000010000010000000144',
    '441111110011114414411110011111144',
    '444444410014444474444410014444444',
    '444444410014444444444410014444444',
    '111111110014411111114410011111111',
    '444444440044412292214440044444444',
    '444444440044412222214440044444444',
    '111111110014411111114410011111111',
    '444444410014444444444410014444444',
    '444444410014444444444410014444444',
    '441111110014411111114410011111144',
    '441000000000000010000000000000144',
    '441000000000000010000000000000144',
    '441331110011110010011110011133144',
    '441000010000000080000000010000144',
    '441000010000000040000000010000144',
    '441110010010011111110010010011144',
    '441000000010000010000010000000144',
    '441000000010000010000010000000144',
    '441001111111110010011111111100144',
    '441000000000000000000000000000144',
    '441000000000000000000000000000144',
    '441111111111111111111111111111144'
  ];

  // ignore: unused_field
  static const _mazeMP1Layout = [
    '4111111111111111111111111111114',
    '4100000001000000000001000000014',
    '4100000001000000000001000000014',
    '4133111001001111111001001113314',
    '4100000000000000000000000000014',
    '4100000000000000000000000000014',
    '4111001001111001001111001001114',
    '4441001001111001001111001001444',
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
    '4100000000000006000000000000014',
    '4100110011111001001111100110014',
    '4133110010000001000000100113314',
    '4100110010000001000000100110014',
    '4100110010011111111100100110014',
    '4100000000000000000000000000014',
    '4100000000000000000000000000014',
    '4111111111111111111111111111114'
  ];

  // ignore: unused_field
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
    '55100000144444744444100000155',
    '11100000144444444444100000111',
    '00000100144111111144100100000',
    '00000100444122922144400100000',
    '11100100446122222164400100111',
    '00000100146111111164100100000',
    '00000100146444444464100100000',
    '11100000166444444466100000111',
    '55100000111144144111100000155',
    '55100100000000100000000100155',
    '55100100000000100000000100155',
    '11100111100100100100111100111',
    '10000000000100800100000000001',
    '10000000000100600100000000001',
    '10011100100111111100100111001',
    '13310000100000000000100001331',
    '10010000100000000000100001001',
    '10010011111100100111111001001',
    '10000000000000100000000000001',
    '10000000000000100000000000001',
    '11111111111111111111111111111'
  ];
}

List<List<int>> _decodeMazeLayout(encodedMazeLayout) {
  List<List<int>> result = [];
  for (String row in encodedMazeLayout) {
    List rowListString = row.split("");
    List<int> rowListInt = [];
    for (String letter in rowListString) {
      rowListInt.add(int.parse(letter));
    }
    result.add(rowListInt);
  }
  return result;
}

Maze maze = Maze();
