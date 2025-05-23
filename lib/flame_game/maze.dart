import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import 'components/lap_angle.dart';
import 'components/mini_pellet.dart';
import 'components/pellet.dart';
import 'components/physics_ball.dart';
import 'components/super_pellet.dart';
import 'components/wall.dart';
import 'pacman_game.dart';

final Map<int, String> mazeNames = <int, String>{
  -1: "T",
  0: "A",
  1: "B",
  2: "C",
};
const int _bufferColumns = 2;

class Maze {
  Maze._({required int mazeId}) {
    setMazeId(mazeId);
  }

  factory Maze({required int mazeId}) {
    assert(_instance == null);
    _instance ??= Maze._(mazeId: mazeId);
    return _instance!;
  }

  ///ensures singleton [Maze]
  static Maze? _instance;

  int get mazeId => _mazeId;

  set mazeId(int i) => setMazeId(i);

  void setMazeId(int id) {
    {
      if (_mazeId == id) {
        return;
      }
      _mazeId = id;
      //items below used every frame so calculate once here
      blockWidth = _blockWidth();
      spriteWidth = _spriteWidth();
      mazeWidth = blockWidth * _mazeLayoutHorizontalLength();
      mazeHeight = blockWidth * _mazeLayoutVerticalLength();
      spriteSize.setAll(spriteWidth);
      cloneThreshold = mazeWidth / 2 - spriteWidth / 2;
      mazeHalfWidth = mazeWidth / 2;
      mazeHalfHeight = mazeHeight / 2;
      //other items
      ghostStart.setFrom(_volatileVectorOfMazeListCode(_kGhostStart));
      pacmanStart.setFrom(_volatileVectorOfMazeListCode(_kPacmanStart));
      _cage.setFrom(_volatileVectorOfMazeListCode(_kCage));
      //item below used regularly
      _ghostStartForIdMap[0] = _ghostStartForId(0);
      _ghostStartForIdMap[1] = _ghostStartForId(1);
      _ghostStartForIdMap[2] = _ghostStartForId(2);
    }
  }

  final Map<int, List<List<String>>> _decodedMazeList =
      <int, List<List<String>>>{
        -1: _decodeMazeLayout(_mazeTutorialLayout),
        0: _decodeMazeLayout(
          enableRotationRaceMode ? _raceTrack : _mazeP1Layout,
        ),
        1: _decodeMazeLayout(_mazeMP4Layout),
        2: _decodeMazeLayout(_mazeMP1Layout),
      };

  List<List<String>> get _mazeLayout => _decodedMazeList[mazeId]!;

  static const int tutorialMazeId = -1;
  static const int defaultMazeId = 0;

  bool get isTutorial => isTutorialMaze(mazeId);

  bool get isDefault => mazeId == defaultMazeId;

  int _mazeId = -10; //set properly in initializer
  final Vector2 ghostStart = Vector2.zero(); //set properly in initializer
  final Vector2 pacmanStart = Vector2.zero(); //set properly in initializer
  final Vector2 _cage = Vector2.zero(); //set properly in initializer
  double mazeWidth = 0; //set properly in initializer
  double mazeHeight = 0; //set properly in initializer
  double blockWidth = 0; //set properly in initializer
  double spriteWidth = 0; //set properly in initializer
  double cloneThreshold = 0; //set properly in initializer
  double mazeHalfWidth = 0; //set properly in initializer
  double mazeHalfHeight = 0; //set properly in initializer
  final Vector2 spriteSize = Vector2.zero(); //set properly in initializer
  final Map<int, Vector2> _ghostStartForIdMap =
      <int, Vector2>{}; //set properly in initializer

  Vector2 ghostStartForId(int idNum) {
    return _ghostStartForIdMap[idNum % 3]!;
  }

  Vector2 _ghostStartForId(int idNum) {
    assert(ghostStart.x != 0 || ghostStart.y != 0); //i.e. not set yet
    return ghostStart.clone()..x += spriteWidth * (idNum % 3 - 1);
  }

  Vector2 ghostSpawnForId(int idNum) {
    return idNum <= 2 ? ghostStartForId(idNum) : _cage;
  }

  int spriteWidthOnScreen(Vector2 size) {
    return (spriteWidth /
            (kVirtualGameSize / flameGameZoom) *
            min(size.x, size.y))
        .toInt();
  }

  double _blockWidth() {
    return kVirtualGameSize /
        flameGameZoom /
        max(_mazeLayoutHorizontalLength(), _mazeLayoutVerticalLength());
  }

  double _spriteWidth() {
    return blockWidth * 2;
  }

  int _mazeLayoutHorizontalLength() {
    return _mazeLayout.isEmpty ? 0 : (_mazeLayout[0].length - _bufferColumns);
  }

  int _mazeLayoutVerticalLength() {
    return _mazeLayout.isEmpty ? 0 : _mazeLayout.length;
  }

  bool _wallAt(int i, int j) {
    return i >= 0 &&
        i < _mazeLayout.length &&
        j >= 0 &&
        j < _mazeLayout[i].length &&
        _mazeLayout[i][j] == _kWall;
  }

  bool _circleAt(int i, int j) {
    assert(_wallAt(i, j));
    return !(_wallAt(i - 1, j) && _wallAt(i + 1, j) ||
        _wallAt(i, j - 1) && _wallAt(i, j + 1));
  }

  bool _movingWallAt(int i, int j) {
    return i >= 0 &&
        i < _mazeLayout.length &&
        j >= 0 &&
        j < _mazeLayout[i].length &&
        _mazeLayout[i][j] == _kMovingWall;
  }

  final Vector2 _volatileInstantConsumeVector2 = Vector2.zero();

  Vector2 _volatileVectorOfMazeListIndex(
    int icore,
    int jcore, {
    double ioffset = 0,
    double joffset = 0,
  }) {
    final double i = ioffset + icore;
    final double j = joffset + jcore;

    /// using [_volatileInstantConsumeVector2]
    /// so we don't have to make new Vector2 every time called
    /// but therefore must instantly consume the output as it may change
    assert(blockWidth != 0); //i.e. not set yet
    _volatileInstantConsumeVector2.setValues(
      (j + 1 / 2 - _mazeLayout[0].length / 2) * blockWidth,
      (i + 1 / 2 - _mazeLayout.length / 2) * blockWidth,
    );
    return _volatileInstantConsumeVector2;
  }

  Vector2 _volatileVectorOfMazeListCode(String code) {
    for (int i = 0; i < _mazeLayout.length; i++) {
      for (int j = 0; j < _mazeLayout[i].length; j++) {
        if (_mazeLayout[i][j] == code) {
          return _volatileVectorOfMazeListIndex(i, j, ioffset: 0.5);
        }
      }
    }
    throw 'Missing maze code $code';
  }

  bool _pelletCodeAtCell(int i, int j) {
    return _mazeLayout[i][j] == _kMiniPellet ||
        _mazeLayout[i][j] == _kSuperPellet ||
        _mazeLayout[i][j] == _kMovingWall;
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
    bool superPelletsEnabled,
    ValueNotifier<int> pelletsRemainingNotifier,
  ) {
    final List<Pellet> result = <Pellet>[];
    final Vector2 center = Vector2.zero();
    for (int i = 0; i < _mazeLayout.length; i++) {
      for (int j = 0; j < _mazeLayout[i].length; j++) {
        center.setFrom(
          _volatileVectorOfMazeListIndex(i, j, ioffset: 0.5, joffset: 0.5),
        );
        if (_pelletAt(i, j)) {
          if (_mazeLayout[i][j] == _kSuperPellet && superPelletsEnabled) {
            result.add(
              SuperPellet(
                position: center,
                pelletsRemainingNotifier: pelletsRemainingNotifier,
              ),
            );
          } else {
            result.add(
              MiniPellet(
                position: center,
                pelletsRemainingNotifier: pelletsRemainingNotifier,
              ),
            );
          }
        }
      }
    }
    return result;
  }

  static const double _mazeInnerWallWidthFactor = 0.7;
  static const double _pixelationBuffer = 0.03;

  bool _topLeftOfBigBlock(int i, int j, {bool moving = false}) {
    final bool Function(int i, int j) localWallAt =
        moving ? _movingWallAt : _wallAt;
    assert(localWallAt(i, j));
    return (!localWallAt(i - 1, j) || !localWallAt(i - 1, j + 1)) &&
        (!localWallAt(i, j - 1) || !localWallAt(i + 1, j - 1)) &&
        !localWallAt(i - 1, j - 1) &&
        localWallAt(i + 1, j) &&
        localWallAt(i, j + 1) &&
        localWallAt(i + 1, j + 1);
  }

  int _bigBlockWidth(
    int i,
    int j, {
    bool singleHeight = true,
    bool moving = false,
  }) {
    final bool Function(int i, int j) localWallAt =
        moving ? _movingWallAt : _wallAt;
    assert(localWallAt(i, j));
    int k = 0;
    while (j + k < _mazeLayout[i].length &&
        (singleHeight || localWallAt(i + 1, j + k + 1)) &&
        localWallAt(i, j + k + 1)) {
      k++;
    }
    return k;
  }

  int _bigBlockHeight(
    int i,
    int j, {
    bool singleWidth = true,
    bool moving = false,
  }) {
    final bool Function(int i, int j) localWallAt =
        moving ? _movingWallAt : _wallAt;
    assert(localWallAt(i, j));
    int l = 0;
    while (i + l < _mazeLayout.length &&
        (singleWidth || localWallAt(i + l + 1, j + 1)) &&
        localWallAt(i + l + 1, j)) {
      l++;
    }
    return l;
  }

  FixtureDef _fixtureDefBlock({
    required Vector2 position,
    required double width,
    required double height,
    double density = 1,
  }) {
    return FixtureDef(
      friction: openSpaceMovement ? 1 : 0,
      restitution: openSpaceMovement ? 0.4 : 0,
      PolygonShape()..setAsBox(width / 2, height / 2, position, 0),
      density: density,
    );
  }

  List<Component> mazeWalls({
    bool includeGround = true,
    bool includeVisualWalls = true,
  }) {
    final List<FixtureDef> fixtureDefs = <FixtureDef>[];
    final List<Component> result = <Component>[];
    final double scale = blockWidth;
    final Vector2 center = Vector2.zero();
    final Vector2 bigBlockCenter = Vector2.zero();
    final Vector2 bigBlockSize = Vector2.zero();
    for (int i = 0; i < _mazeLayout.length; i++) {
      for (int j = 0; j < _mazeLayout[i].length; j++) {
        center.setFrom(_volatileVectorOfMazeListIndex(i, j));
        if (_wallAt(i, j)) {
          if (_circleAt(i, j)) {
            fixtureDefs.add(
              FixtureDef(CircleShape(radius: scale / 2, position: center)),
            );
            result.add(
              WallCircleVisual(
                position: center,
                radius: scale / 2 * _mazeInnerWallWidthFactor,
              ),
            );
          }
          if (!_wallAt(i, j - 1)) {
            final int width = _bigBlockWidth(i, j);
            if (width > 0) {
              bigBlockCenter
                ..setFrom(center)
                ..x += scale * width / 2;
              bigBlockSize.setValues(
                scale * (width + _pixelationBuffer),
                scale * _mazeInnerWallWidthFactor,
              );
              fixtureDefs.add(
                _fixtureDefBlock(
                  position: bigBlockCenter,
                  width: scale * (width + _pixelationBuffer),
                  height: scale,
                ),
              );
              result.add(
                WallRectangleVisual(
                  position: bigBlockCenter,
                  size: bigBlockSize,
                ),
              );
            }
          }
          if (!_wallAt(i - 1, j)) {
            final int height = _bigBlockHeight(i, j);
            if (height > 0) {
              bigBlockCenter
                ..setFrom(center)
                ..y += scale * height / 2;
              bigBlockSize.setValues(
                scale * _mazeInnerWallWidthFactor,
                scale * (height + _pixelationBuffer),
              );
              fixtureDefs.add(
                _fixtureDefBlock(
                  position: bigBlockCenter,
                  width: scale,
                  height: scale * (height + _pixelationBuffer),
                ),
              );
              result.add(
                WallRectangleVisual(
                  position: bigBlockCenter,
                  size: bigBlockSize,
                ),
              );
            }
          }
          if (_topLeftOfBigBlock(i, j)) {
            final int width = _bigBlockWidth(i, j, singleHeight: false);
            final int height = _bigBlockHeight(i, j, singleWidth: false);
            if (width > 0 && height > 0) {
              bigBlockCenter
                ..setFrom(center)
                ..x += scale * width / 2
                ..y += scale * height / 2;
              bigBlockSize.setValues(scale * width, scale * height);
              result.add(
                WallRectangleVisual(
                  position: bigBlockCenter,
                  size: bigBlockSize,
                ),
              );
            }
          }
        }
      }
    }
    if (!includeVisualWalls) {
      result.clear();
    }
    if (includeGround) {
      result.add(WallGround(fixtureDefs: fixtureDefs));
    }
    return result;
  }

  List<Component> mazeBlockingWalls() {
    final List<Component> result = <Component>[];
    final double scale = blockWidth;
    const int width = 7;
    final Vector2 size = Vector2(
      scale * width,
      scale * _mazeLayoutVerticalLength(),
    );
    final Vector2 position = Vector2(
      scale * (_mazeLayoutHorizontalLength() / 2 + width / 2),
      0,
    );
    result
      ..add(WallRectangleVisual(position: position, size: size))
      ..add(WallRectangleVisual(position: position..x *= -1, size: size));
    return result;
  }

  List<Component> mazeMovingWalls({
    bool includeGround = true,
    bool includeVisualWalls = true,
  }) {
    const double lubricationScaleFactor = 0.98;
    final List<Component> result = <Component>[];
    final double scale = blockWidth;
    final Vector2 center = Vector2.zero();
    final Vector2 bigBlockCenter = Vector2.zero();
    for (int i = 0; i < _mazeLayout.length; i++) {
      for (int j = 0; j < _mazeLayout[i].length; j++) {
        center.setFrom(_volatileVectorOfMazeListIndex(i, j));
        if (_movingWallAt(i, j)) {
          if (_topLeftOfBigBlock(i, j, moving: true)) {
            final int width = _bigBlockWidth(i, j, moving: true);
            final int height = _bigBlockHeight(i, j, moving: true);
            if (width > 0 && height > 0) {
              bigBlockCenter
                ..setFrom(center)
                ..x += scale * width / 2
                ..y += scale * height / 2;
              result.add(
                (WallDynamic(
                  position: bigBlockCenter,
                  fixtureDefs: <FixtureDef>[
                    _fixtureDefBlock(
                      position: Vector2(0, 0),
                      width: scale * (width + 1) * lubricationScaleFactor,
                      height: scale * (height + 1) * lubricationScaleFactor,
                      density: 10,
                    ),
                  ],
                  //bigBlockCenter, //
                )),
              );
            }
          }
        }
      }
    }
    return result;
  }

  static const String _kMiniPellet = "0"; //quad of dots
  static const String _kWall = "1";
  static const String _kMovingWall = "6";

  // ignore: unused_field
  static const String _kLair = "2";
  static const String _kSuperPellet = "3"; //quad top
  // ignore: unused_field
  static const String _kEmpty = "4";
  static const String _kGhostStart = "7";
  static const String _kPacmanStart = "8";
  static const String _kCage = "9";

  // ignore: unused_field
  static const List<String> _mazeP1Layout = <String>[
    '4111111111111111111111111111114',
    '4100000660000001000000660000014',
    '4100000660000001000000660000014',
    '4133111661111001001111661113314',
    '4100111001111001001111001110014',
    '4100000000000066600000000000014',
    '4100000000000066600000000000014',
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
    '4100000000000066600000000000014',
    '4100000000000066600000000000014',
    '4111111111111111111111111111114',
  ];

  static const List<String> _mazeMP4Layout = <String>[
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
    '1111000001444444444441000001111',
    '4000001001441111111441001000004',
    '4000001004441229221444001000004',
    '1111001004441222221444001001111',
    '4000001001441111111441001000004',
    '4000001001444444444441001000004',
    '1111000001444444444441000001111',
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
    '4111111111111111111111111111114',
  ];

  static const List<String> _mazeMP1Layout = <String>[
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
    '4111111111111111111111111111114',
  ];

  static const List<String> _mazeTutorialLayout = <String>[
    '4111111111111111111111111111114',
    '4100000444444441444444440000014',
    '4100000444444441444444440000014',
    '4133111441111441441111441113314',
    '4100111441111441441111441110014',
    '4144444444444000004444444444414',
    '4144444444444000004444444444414',
    '4144111441441111111441441114414',
    '4144444441444441444441444444414',
    '4144444441444441444441444444414',
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
    '4100000444444441444444440000014',
    '4100000444444441444444440000014',
    '4133111441111441441111441113314',
    '4100001444444448444444441000014',
    '4100001444444444444444441000014',
    '4111441441441111111441441441114',
    '4144444441444441444441444444414',
    '4144444441444441444441444444414',
    '4144111111111441441111111114414',
    '4100000000000000000000000000014',
    '4100000000000000000000000000014',
    '4111111111111111111111111111114',
  ];

  // ignore: unused_field
  static const List<String> _raceTrack = <String>[
    '4111111111111111111111111111114',
    '4144444444444411144444444444414',
    '4144444444444448444444444444414',
    '4144144444446647466444444414414',
    '4144444444446644466444444444414',
    '4144444444444444444444444444414',
    '4144444111111111111111114444414',
    '4144444111111111111111114444414',
    '4144444114444444444444114444414',
    '4144444114444444444444114444414',
    '4144444114444444444444114444414',
    '4146644114444444444444114466414',
    '4146644114444444444444114466414',
    '4144444114444444444444114444414',
    '4144441114444449444444111444414',
    '4144441114444444444444111444414',
    '4144441114444444444444111444414',
    '4144444114444444444444114444414',
    '4144444114444444444444114444414',
    '4144444114444444444444114444414',
    '4144444114444444444444114444414',
    '4144444114444444444444114444414',
    '4144444114444444444444114444414',
    '4144444114444444444444114444414',
    '4114444111111111111111114444114',
    '4114444111114444444111114444114',
    '4144444444444444444444444444414',
    '4144444444444661664444444444414',
    '4144444444444664664444444444414',
    '4144444444444444444444444444414',
    '4144444111444444444441114444414',
    '4111111111111111111111111111114',
  ];
}

List<List<String>> _decodeMazeLayout(List<String> encodedMazeLayout) {
  final List<List<String>> result = <List<String>>[];
  for (final String row in encodedMazeLayout) {
    result.add(row.split(""));
  }
  return result;
}

bool isTutorialMaze(int mazeId) {
  return mazeId == Maze.tutorialMazeId;
}

Maze maze = Maze(mazeId: 0);
