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
  int _mazeId = 0;

  int get mazeId => _mazeId;

  set mazeId(int i) => setMazeIdReal(i);

  void setMazeIdReal(int i) {
    {
      _mazeId = i;
      ghostStart = _vectorOfMazeListTargetNumber(7);
      pacmanStart = _vectorOfMazeListTargetNumber(8);
      cage = _vectorOfMazeListTargetNumber(9);
    }
  }

  final List decodedMazeList = [
    _decodeMazeLayout(_maze1Layout),
    _decodeMazeLayout(_mazeMP4Layout),
    _decodeMazeLayout(_mazeMP1Layout)
  ];

  get _mazeLayout => decodedMazeList[_mazeId];
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

  PelletWrapper pellets(
      ValueNotifier pelletsRemainingNotifier, bool superPelletsEnabled) {
    final result = PelletWrapper();
    //pelletsRemainingNotifier.value = 0;
    for (int i = 0; i < _mazeLayout.length; i++) {
      for (int j = 0; j < _mazeLayout[i].length; j++) {
        Vector2 center = _vectorOfMazeListIndex(i, j,
            ioffset: _largeSprites ? 1 / 2 : 0,
            joffset: _largeSprites ? 1 / 2 : 0);
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

// 0 - pac-dots
// 1 - wall
// 2 - ghost-lair
// 3 - power-pellet
// 4 - empty
// 5 - outside
// 6 - below 0
// 7 - ghostStart
// 8 - pacmanStart
// 9 - cage

  // ignore: unused_field
  static const _maze1Layout = [
    '551111111111111111111111111111155',
    '551000000000000610000000000006155',
    '551066660666660610666660666606155',
    '551361110611110410611110611136155',
    '551061110611110410611110611106155',
    '551000000000000000000000000006155',
    '551066660660666646660660666606155',
    '551061110610411111110610611106155',
    '551000000610000610000610000006155',
    '551666660616644614646610666666155',
    '551111110611114414411110611111155',
    '555555510614444474444410615555555',
    '555555510614444444444410615555555',
    '111111110614411111114410611111111',
    '444444440644412292214440644444444',
    '444444440644412222214440644444444',
    '111111110614411111114410611111111',
    '555555510614444444444410615555555',
    '555555510614444444444410615555555',
    '551111110614411111114410611111155',
    '551000000000000610000000000006155',
    '551066660666660610666660666606155',
    '551341110611110410611110611136155',
    '551000410000000480000000610006155',
    '551640410660666646660660610466155',
    '551110410610411111110610610411155',
    '551000000610000610000610000006155',
    '551066666616640610646616666606155',
    '551041111111110410611111111106155',
    '551000000000000000000000000006155',
    '551666666666666646666666666666155',
    '551111111111111111111111111111155'
  ];

  // ignore: unused_field
  static const _maze2LayoutP = [
    '551441555555515514455555555144155',
    '111441111111114414411111111144111',
    '444000000000000610000000000006444',
    '444066660666660610666660666606444',
    '111361110611110410611110611136111',
    '551061110611110410611110611106155',
    '551000000000000000000000000006155',
    '551066660660666646660660666606155',
    '111061110610411111110610611106111',
    '444000000610000610000610000006444',
    '444666660616644614646610666666444',
    '111111110611114414411110611111111',
    '555555510614444474444410615555555',
    '555555510614444444444410615555555',
    '111111110614411111114410611111111',
    '444444440644412292214440644444444',
    '444444440644412222214440644444444',
    '111111110614411111114410611111111',
    '555555510614444444444410615555555',
    '555555510614444444444410615555555',
    '111111110614411111114410611111111',
    '444000000000000610000000000006444',
    '444066660666660610666660666606444',
    '111341110611110410611110611136111',
    '551000410000000480000000610006155',
    '551640410660666646660660610466155',
    '551110410610411111110610610411155',
    '551000000610000610000610000006155',
    '551066666616640610646616666606155',
    '111041111111110410611111111106111',
    '444000000000000000000000000006444',
    '444666666666666646666666666666444',
    '111441111111114414411111111144111'
  ];

  // ignore: unused_field
  static const _smallSpritesMazeXLayout = [
    '511111111111111111115',
    '510000000010000000015',
    '513110111010111011315',
    '510000000000000000015',
    '510110101111101011015',
    '510000100010001000015',
    '511110111414111011115',
    '555510144474441015555',
    '111110141111141011111',
    '444440441292144044444',
    '111110141111141011111',
    '555510144444441015555',
    '511110141111141011115',
    '510000000010000000015',
    '510110111010111011015',
    '513010000080000010315',
    '511010101111101010115',
    '510000100010001000015',
    '510111111010111111015',
    '510000000000000000015',
    '511111111111111111115'
  ];

  // ignore: unused_field
  static const _mazeMP1Layout = [
    '5111111111111111111111111111115',
    '5100000061000000000061000000615',
    '5106666061066666666061066660615',
    '5136111061061111111061061113615',
    '5100000000000000000000000000615',
    '5166066066666064066666066066615',
    '5111061061111061061111061061115',
    '5551061061111061061111061061555',
    '1111061061111061061111061061111',
    '4444061000000061000000061064444',
    '4444061666666661666666661064444',
    '1111061111441111111441111061111',
    '5551000006444447444440000061555',
    '5551066666444444444446666061555',
    '5551061111441111111441111061555',
    '5551061006441229221440061061555',
    '5551061066441222221446061061555',
    '1111061061441111111441061061111',
    '4444000061444444444441000064444',
    '4444066661444444444441666064444',
    '1111061111111061061111111061111',
    '5551000000000061000000000061555',
    '5551066666066661666066666061555',
    '5111061111061111111061111061115',
    '5100000000000068000000000000615',
    '5106660666666066066666606660615',
    '5106110611111061061111106110615',
    '5136110610000061000006106113615',
    '5106110610666661666606106110615',
    '5106110610611111111106106110615',
    '5100000000000000000000000000615',
    '5166666666666666666666666666615',
    '5111111111111111111111111111115'
  ];

  // ignore: unused_field
  static const _mazeMP4Layout = [
    '11111111111111111111111111111',
    '10000000000000000000000000061',
    '10660666606466666406666066061',
    '10610611106111111106111061061',
    '13610611106100006106111061361',
    '10610000006104406100000061061',
    '10616606606104106106606661061',
    '10611106106104106106106111061',
    '10000006100006100006100000061',
    '16606666166666166666166606661',
    '11104111111144144111111106111',
    '55100006144444744444100006155',
    '11105406144444444444106406111',
    '00005106144111111144106100006',
    '66665106444122922144406166666',
    '11111106446122222164406111111',
    '00004106146111111164106100006',
    '44404106146444444464106106446',
    '11100006166444444466100006111',
    '55104406111144144111106406155',
    '55105100000006100000006106155',
    '55105166606606106606666106155',
    '11104111104106106106111106111',
    '10000000006106806100000000061',
    '10446406606166666106606464061',
    '10611104104111111106106111061',
    '13610004100000000006100061361',
    '10610644164606406646144061061',
    '10610411111104106111111061061',
    '10000000000006100000000000061',
    '16646666666666166666666664661',
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
