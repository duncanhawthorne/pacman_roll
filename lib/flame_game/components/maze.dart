//import 'package:flutter/cupertino.dart';

import 'dart:ui';

import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../helper.dart';
import 'package:flame/components.dart';
import 'super_pellet.dart';
import 'mini_pellet.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

final Paint blackBackgroundPaint = Paint()
  ..color = globalPalette.flameGameBackground.color;
final Paint blueMazePaint = Paint()..color = globalPalette.blueMaze;

class Maze {
  get ghostStart => Vector2(0, maze1 ? -3.5 : -3) * blockWidth();

  get pacmanStart => Vector2(0, maze1 ? 8.5 : 5) * blockWidth();

  get cage => Vector2(0, maze1 ? -0.5 : -1) * blockWidth();

  get leftPortal =>
      Vector2(-(_mazeLayoutLength() - 1) / 2 * 0.99, maze1 ? -0.5 : -1) *
      blockWidth();

  get rightPortal =>
      Vector2((_mazeLayoutLength() - 1) / 2 * 0.99, maze1 ? -0.5 : -1) *
      blockWidth();

  get offScreen => Vector2(0, 1000) * spriteWidth();

  static const mazeWallWidthFactor = 0.7;
  static const double pixelationBuffer = 1.03;
  static const bool maze1 = true;
  static const gameScaleFactor = maze1 ? 1.0 : 0.95;

  get pelletScaleFactor => maze1 ? 0.4 : 0.46;

  double blockWidth() {
    return kSquareNotionalSize /
        flameGameZoom /
        _mazeLayoutLength() *
        gameScaleFactor;
  }

  double spriteWidth() {
    return blockWidth() * (maze1 ? 2 : 1);
  }

  int _mazeLayoutLength() {
    return _wrappedMazeLayout.isEmpty ? 0 : _wrappedMazeLayout[0].length;
  }

  List<Component> pelletsAndSuperPellets(
      ValueNotifier pelletsRemainingNotifier) {
    List<Component> result = [];
    pelletsRemainingNotifier.value = 0;
    double scale = blockWidth();
    for (int i = 0; i < _wrappedMazeLayout.length; i++) {
      for (int j = 0; j < _wrappedMazeLayout[i].length; j++) {
        Vector2 center = Vector2(0, 0);
        if (maze1) {
          center = Vector2(j + 1 - _wrappedMazeLayout[0].length / 2,
                  i + 1 - _wrappedMazeLayout.length / 2) *
              scale;
        } else {
          center = Vector2(j + 1 / 2 - _wrappedMazeLayout[0].length / 2,
                  i + 1 / 2 - _wrappedMazeLayout.length / 2) *
              scale;
        }
        if (_wrappedMazeLayout[i][j] == 0) {
          result.add(MiniPelletCircle(position: center));
        }
        if (_wrappedMazeLayout[i][j] == 3) {
          result.add(SuperPelletCircle(position: center));
        }
      }
    }
    return result;
  }

  bool _center(int i, int j) {
    if (i >= _wrappedMazeLayout.length ||
        i < 0 ||
        j >= _wrappedMazeLayout[i].length ||
        j < 0) {
      return false;
    } else {
      return _wrappedMazeLayout[i][j] == 1;
    }
  }

  bool _circleAt(int i, int j) {
    assert(_center(i, j));
    return !(_center(i - 1, j) && _center(i + 1, j) ||
        _center(i, j - 1) && _center(i, j + 1));
  }

  List<Component> mazeWalls() {
    List<Component> result = [];
    double scale = blockWidth();
    for (int i = 0; i < _wrappedMazeLayout.length; i++) {
      for (int j = 0; j < _wrappedMazeLayout[i].length; j++) {
        Vector2 center = Vector2(j + 1 / 2 - _wrappedMazeLayout[0].length / 2,
                i + 1 / 2 - _wrappedMazeLayout.length / 2) *
            scale;
        if (_center(i, j)) {
          if (_circleAt(i, j)) {
            result.add(MazeWallCircleGround(center, scale / 2));
          }
          if (_center(i, j + 1)) {
            result.add(MazeWallRectangleGround(center + Vector2(scale / 2, 0),
                scale * pixelationBuffer, scale));
          }
          if (_center(i + 1, j)) {
            result.add(MazeWallRectangleGround(center + Vector2(0, scale / 2),
                scale, scale * pixelationBuffer));
          }
        }
      }
    }

    for (int i = 0; i < _wrappedMazeLayout.length; i++) {
      for (int j = 0; j < _wrappedMazeLayout[i].length; j++) {
        Vector2 center = Vector2(j + 1 / 2 - _wrappedMazeLayout[0].length / 2,
                i + 1 / 2 - _wrappedMazeLayout.length / 2) *
            scale;
        if (_center(i, j)) {
          if (_circleAt(i, j)) {
            result.add(MazeWallCircleVisual(
                position: center, radius: scale / 2 * mazeWallWidthFactor));
          }
          if (_center(i, j + 1)) {
            result.add(MazeWallSquareVisual(
                position: center + Vector2(scale / 2, 0),
                widthx: scale * pixelationBuffer,
                heightx: scale * mazeWallWidthFactor));
          }
          if (_center(i + 1, j)) {
            result.add(MazeWallSquareVisual(
                position: center + Vector2(0, scale / 2),
                widthx: scale * mazeWallWidthFactor,
                heightx: scale * pixelationBuffer));
          }
          if (_center(i + 1, j) && _center(i, j + 1) && _center(i + 1, j + 1)) {
            result.add(MazeWallSquareVisual(
                position: center + Vector2(scale / 2, scale / 2),
                widthx: scale * mazeWallWidthFactor,
                heightx: scale * pixelationBuffer));
          }
        }
      }
    }
    return result;
  }

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

  final _wrappedMazeLayout =
      maze1 ? _decodeMazeLayout(_maze1Layout) : _maze2Layout;
}

class MazeWallSquareVisual extends RectangleComponent {
  MazeWallSquareVisual(
      {required super.position, required widthx, required heightx})
      : super(
            size: Vector2(widthx, heightx),
            anchor: Anchor.center,
            paint: blackBackgroundPaint);
  double widthx = 0;
  double heightx = 0;
}

class MazeWallCircleVisual extends CircleComponent {
  MazeWallCircleVisual({required super.radius, required super.position})
      : super(anchor: Anchor.center, paint: blackBackgroundPaint); //NOTE BLACK
}

class MazeWallRectangleGround extends BodyComponent {
  final Vector2 _position;
  final double width;
  final double height;

  MazeWallRectangleGround(this._position, this.width, this.height);

  @override
  Body createBody() {
    final shape = PolygonShape();
    paint = blueMazePaint;

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
        position: _position - Vector2(width / 2, height / 2));
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}

class MazeWallCircleGround extends BodyComponent {
  final Vector2 _position;
  final double _radius;

  MazeWallCircleGround(this._position, this._radius);

  @override
  Body createBody() {
    final shape = CircleShape();
    paint = blueMazePaint;

    shape.radius = _radius;
    final fixtureDef = FixtureDef(shape);

    final bodyDef = BodyDef(type: BodyType.static, position: _position);
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
