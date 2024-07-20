import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../style/palette.dart';
import '../pacman_game.dart';
import 'mini_pellet.dart';
import 'super_pellet.dart';
import 'wrapper_no_events.dart';

final Paint _blackBackgroundPaint = Paint()
//..filterQuality = FilterQuality.none
////..color = Color.fromARGB(50, 100, 100, 100)
//..isAntiAlias = false
  ..color = Palette.black;
final Paint _blueMazePaint = Paint()
//..filterQuality = FilterQuality.none
////..color = Color.fromARGB(50, 100, 100, 100)
//..isAntiAlias = false
  ..color = Palette.blueMaze;

class GameSize {}

GameSize gameSize = GameSize();

class Maze {
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
    //'555555555555555555555555555555555',
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

  static const chosenMaze = _maze1Layout;

  static const _mazeInnerWallWidthFactor = 0.7;
  static const double _pixelationBuffer = 0.03;
  static const bool _largeSprites = chosenMaze != _smallSpritesMazeXLayout;
  static const _mazeScaleFactor = _largeSprites ? 0.95 : 0.95;
  final _mazeLayout = _decodeMazeLayout(chosenMaze);

  late final ghostStart = _vectorOfMazeListTargetNumber(7);

  late final pacmanStart = _vectorOfMazeListTargetNumber(8);

  late final cage = _vectorOfMazeListTargetNumber(9);

  //late final offScreen = cage; //_vectorOfMazeListIndex(100, 0);

  static const pelletScaleFactor = _largeSprites ? 0.4 : 0.46;

  Vector2 ghostStartForId(int idNum) {
    return (idNum == 100 ? cage : ghostStart) +
        Vector2(maze.spriteWidth() * (idNum <= 2 ? (idNum - 1) : 0), 0);
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
        max(_mazeLayoutHorizontalLength(), _mazeLayoutVerticalLength()) *
        _mazeScaleFactor;
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

  PelletWrapperNoEvents pellets(
      ValueNotifier pelletsRemainingNotifier, bool superPelletsEnabled) {
    final result = PelletWrapperNoEvents();
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

  WallWrapperNoEvents mazeWalls() {
    final result = WallWrapperNoEvents();
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
                  scale * k + _pixelationBuffer,
                  scale));
              result.add(MazeWallSquareVisual(
                  position: center + Vector2(scale * k / 2, 0),
                  width: scale * k + _pixelationBuffer,
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
                  scale * k + _pixelationBuffer));
              result.add(MazeWallSquareVisual(
                  position: center + Vector2(0, scale * k / 2),
                  width: scale * _mazeInnerWallWidthFactor,
                  height: scale * k + _pixelationBuffer));
            }
          }
          if (_wallAt(i + 1, j) && _wallAt(i, j + 1) && _wallAt(i + 1, j + 1)) {
            result.add(MazeWallSquareVisual(
                position: center + Vector2(scale / 2, scale / 2),
                width: scale,
                height: scale));
          }
        }
      }
    }
    return result;
  }
}

class MazeWallSquareVisual extends RectangleComponent with IgnoreEvents {
  MazeWallSquareVisual(
      {required super.position, required width, required height})
      : super(
            size: Vector2(width, height),
            anchor: Anchor.center,
            paint: _blackBackgroundPaint);
}

class MazeWallCircleVisual extends CircleComponent with IgnoreEvents {
  MazeWallCircleVisual({required super.radius, required super.position})
      : super(anchor: Anchor.center, paint: _blackBackgroundPaint); //NOTE BLACK
}

class MazeWallRectangleGround extends BodyComponent with IgnoreEvents {
  @override
  final Vector2 position;
  final double width;
  final double height;

  MazeWallRectangleGround(this.position, this.width, this.height);

  @override
  // ignore: overridden_fields
  final renderBody = true;

  @override
  final priority = -2;

  @override
  Body createBody() {
    final shape = PolygonShape();
    paint = _blueMazePaint;

    final List<Vector2> vertices = [
      Vector2(0, 0),
      Vector2(width, 0),
      Vector2(width, height),
      Vector2(0, height),
    ];

    shape.set(vertices);
    final fixtureDef = FixtureDef(shape);

    final bodyDef = BodyDef(
        type: BodyType.static,
        position: position - Vector2(width / 2, height / 2));
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}

class MazeWallCircleGround extends BodyComponent with IgnoreEvents {
  @override
  final Vector2 position;
  final double radius;

  MazeWallCircleGround(this.position, this.radius);

  @override
  // ignore: overridden_fields
  final renderBody = true;

  @override
  final priority = -2;

  @override
  Body createBody() {
    final shape = CircleShape();
    paint = _blueMazePaint;

    shape.radius = radius;
    final fixtureDef = FixtureDef(shape);

    final bodyDef = BodyDef(type: BodyType.static, position: position);
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
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
