import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../style/palette.dart';
import '../pacman_game.dart';
import 'mini_pellet.dart';
import 'super_pellet.dart';

final Paint _blackBackgroundPaint = Paint()..color = Palette.black;
final Paint _blueMazePaint = Paint()..color = Palette.blueMaze;

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

  static const _maze1Layout = [
    '555555555555555555555555555555555',
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
    '555555510614444444444410615555555',
    '555555510614444444444410615555555',
    '111111110614411111114410611111111',
    '444444440644412222214440644444444',
    '444444440644412222214440644444444',
    '111111110614411111114410611111111',
    '555555510614444444444410615555555',
    '555555510614444444444410615555555',
    '551111110614411111114410611111155',
    '551000000000000610000000000006155',
    '551066660666660610666660666606155',
    '551341110611110410611110611136155',
    '551000410000000440000000610006155',
    '551640410660666646660660610466155',
    '551110410610411111110610610411155',
    '551000000610000610000610000006155',
    '551066666616640610646616666606155',
    '551041111111110410611111111106155',
    '551000000000000000000000000006155',
    '551666666666666646666666666666155',
    '551111111111111111111111111111155'
  ];

  static const _maze2Layout = [
    [5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5],
    [5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5],
    [5, 1, 3, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 3, 1, 5],
    [5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5],
    [5, 1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 5],
    [5, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 5],
    [5, 1, 1, 1, 1, 0, 1, 1, 1, 4, 1, 4, 1, 1, 1, 0, 1, 1, 1, 1, 5],
    [5, 5, 5, 5, 1, 0, 1, 4, 4, 4, 4, 4, 4, 4, 1, 0, 1, 5, 5, 5, 5],
    [1, 1, 1, 1, 1, 0, 1, 4, 1, 1, 1, 1, 1, 4, 1, 0, 1, 1, 1, 1, 1],
    [4, 4, 4, 4, 4, 0, 4, 4, 1, 2, 2, 2, 1, 4, 4, 0, 4, 4, 4, 4, 4],
    [1, 1, 1, 1, 1, 0, 1, 4, 1, 1, 1, 1, 1, 4, 1, 0, 1, 1, 1, 1, 1],
    [5, 5, 5, 5, 1, 0, 1, 4, 4, 4, 4, 4, 4, 4, 1, 0, 1, 5, 5, 5, 5],
    [5, 1, 1, 1, 1, 0, 1, 4, 1, 1, 1, 1, 1, 4, 1, 0, 1, 1, 1, 1, 5],
    [5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5],
    [5, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 5],
    [5, 1, 3, 0, 1, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 1, 0, 3, 1, 5],
    [5, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 5],
    [5, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 5],
    [5, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 5],
    [5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5],
    [5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5]
  ];

  static const _mazeInnerWallWidthFactor = 0.7;
  static const double _pixelationBuffer = 1.03;
  static const bool _maze1 = true;
  static const _mazeScaleFactor = _maze1 ? 1.0 : 0.95;
  final _mazeLayout = _maze1 ? _decodeMazeLayout(_maze1Layout) : _maze2Layout;

  late final ghostStart = Vector2(0, _maze1 ? -3.5 : -3) * blockWidth();

  late final pacmanStart = Vector2(0, _maze1 ? 8.5 : 5) * blockWidth();

  late final cage = Vector2(0, _maze1 ? -0.5 : -1) * blockWidth();

  late final leftPortal =
      Vector2(-(_mazeLayoutLength() - 1) / 2 * 0.99, _maze1 ? -0.5 : -1) *
          blockWidth();

  late final rightPortal =
      Vector2((_mazeLayoutLength() - 1) / 2 * 0.99, _maze1 ? -0.5 : -1) *
          blockWidth();

  late final offScreen = Vector2(0, 1000) * spriteWidth();

  late final pelletScaleFactor = _maze1 ? 0.4 : 0.46;

  int spriteWidthOnScreen(Vector2 size) {
    return (spriteWidth() /
            (kSquareNotionalSize / flameGameZoom) *
            min(size.x, size.y))
        .toInt();
  }

  double blockWidth() {
    return kSquareNotionalSize /
        flameGameZoom /
        _mazeLayoutLength() *
        _mazeScaleFactor;
  }

  double spriteWidth() {
    return blockWidth() * (_maze1 ? 2 : 1);
  }

  int _mazeLayoutLength() {
    return _mazeLayout.isEmpty ? 0 : _mazeLayout[0].length;
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

  List<Component> pellets(ValueNotifier pelletsRemainingNotifier) {
    List<Component> result = [];
    pelletsRemainingNotifier.value = 0;
    double scale = blockWidth();
    for (int i = 0; i < _mazeLayout.length; i++) {
      for (int j = 0; j < _mazeLayout[i].length; j++) {
        Vector2 center = Vector2(0, 0);
        if (_maze1) {
          center = Vector2(j + 1 - _mazeLayout[0].length / 2,
                  i + 1 - _mazeLayout.length / 2) *
              scale;
        } else {
          center = Vector2(j + 1 / 2 - _mazeLayout[0].length / 2,
                  i + 1 / 2 - _mazeLayout.length / 2) *
              scale;
        }
        if (_mazeLayout[i][j] == 0) {
          result.add(MiniPelletCircle(position: center));
        }
        if (_mazeLayout[i][j] == 3) {
          result.add(SuperPelletCircle(position: center));
        }
      }
    }
    return result;
  }

  List<Component> mazeWalls() {
    List<Component> result = [];
    double scale = blockWidth();
    for (int i = 0; i < _mazeLayout.length; i++) {
      for (int j = 0; j < _mazeLayout[i].length; j++) {
        Vector2 center = Vector2(j + 1 / 2 - _mazeLayout[0].length / 2,
                i + 1 / 2 - _mazeLayout.length / 2) *
            scale;
        if (_wallAt(i, j)) {
          if (_circleAt(i, j)) {
            result.add(MazeWallCircleGround(center, scale / 2));
          }
          if (_wallAt(i, j + 1)) {
            result.add(MazeWallRectangleGround(center + Vector2(scale / 2, 0),
                scale * _pixelationBuffer, scale));
          }
          if (_wallAt(i + 1, j)) {
            result.add(MazeWallRectangleGround(center + Vector2(0, scale / 2),
                scale, scale * _pixelationBuffer));
          }
        }
      }
    }

    for (int i = 0; i < _mazeLayout.length; i++) {
      for (int j = 0; j < _mazeLayout[i].length; j++) {
        Vector2 center = Vector2(j + 1 / 2 - _mazeLayout[0].length / 2,
                i + 1 / 2 - _mazeLayout.length / 2) *
            scale;
        if (_wallAt(i, j)) {
          if (_circleAt(i, j)) {
            result.add(MazeWallCircleVisual(
                position: center,
                radius: scale / 2 * _mazeInnerWallWidthFactor));
          }
          if (_wallAt(i, j + 1)) {
            result.add(MazeWallSquareVisual(
                position: center + Vector2(scale / 2, 0),
                width: scale * _pixelationBuffer,
                height: scale * _mazeInnerWallWidthFactor));
          }
          if (_wallAt(i + 1, j)) {
            result.add(MazeWallSquareVisual(
                position: center + Vector2(0, scale / 2),
                width: scale * _mazeInnerWallWidthFactor,
                height: scale * _pixelationBuffer));
          }
          if (_wallAt(i + 1, j) && _wallAt(i, j + 1) && _wallAt(i + 1, j + 1)) {
            result.add(MazeWallSquareVisual(
                position: center + Vector2(scale / 2, scale / 2),
                width: scale * _mazeInnerWallWidthFactor,
                height: scale * _pixelationBuffer));
          }
        }
      }
    }
    return result;
  }
}

class MazeWallSquareVisual extends RectangleComponent {
  MazeWallSquareVisual(
      {required super.position, required width, required height})
      : super(
            size: Vector2(width, height),
            anchor: Anchor.center,
            paint: _blackBackgroundPaint);
}

class MazeWallCircleVisual extends CircleComponent {
  MazeWallCircleVisual({required super.radius, required super.position})
      : super(anchor: Anchor.center, paint: _blackBackgroundPaint); //NOTE BLACK
}

class MazeWallRectangleGround extends BodyComponent {
  @override
  final Vector2 position;
  final double width;
  final double height;

  MazeWallRectangleGround(this.position, this.width, this.height);

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

class MazeWallCircleGround extends BodyComponent {
  @override
  final Vector2 position;
  final double radius;

  MazeWallCircleGround(this.position, this.radius);

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
