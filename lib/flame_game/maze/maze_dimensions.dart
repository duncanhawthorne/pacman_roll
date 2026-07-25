import 'dart:math';

import 'package:flame/components.dart';

import '../components/physics_ball.dart';
import '../custom_game.dart';
import 'maze_layout.dart';
import 'maze_tiles.dart';

/// Calculates and stores spatial dimensions and key positions for the maze.
class MazeDimensions {
  MazeDimensions({required MazeLayout layout}) : _layout = layout;

  final MazeLayout _layout;

  /// Starting position for ghosts.
  late final Vector2 ghostStart = _vectorOfMazeTile(Tile.ghostStart);

  /// Starting position for Pacman.
  late final Vector2 pacmanStart = _vectorOfMazeTile(Tile.pacmanStart);

  late final Vector2 _cage = _vectorOfMazeTile(Tile.cage);

  /// Total width of the maze in game units.
  late final double mazeWidth = blockWidth * _layout.lengthHBuffered;

  /// Total height of the maze in game units.
  late final double mazeHeight = blockWidth * _layout.length;

  /// Width of a single grid block.
  late final double blockWidth = _blockWidth();

  /// Width of game characters (sprites).
  late final double spriteWidth = _spriteWidth();

  /// Threshold for wrapping clones around the maze edges.
  late final double cloneThreshold = mazeWidth / 2 - spriteWidth / 2;

  late final double mazeHalfWidthPhysics = mazeWidth / 2 * physicsScale;
  late final double mazeHalfHeightPhysics = mazeHeight / 2 * physicsScale;

  /// Size of game characters as a Vector2.
  late final Vector2 spriteSize = Vector2.zero()..setAll(spriteWidth);
  late final Map<int, Vector2> _ghostStartForIdMap = <int, Vector2>{
    0: _ghostStartForId(0),
    1: _ghostStartForId(1),
    2: _ghostStartForId(2),
  };

  double _blockWidth() {
    return worldSquareSize / max(_layout.lengthHBuffered, _layout.length);
  }

  double _spriteWidth() {
    return blockWidth * 2;
  }

  /// Converts grid coordinates (i, j) to world coordinates.
  Vector2 locationOfIJ(
    int icore,
    int jcore, {
    double ioffset = 0,
    double joffset = 0,
    required Vector2 output,
  }) {
    final double i = ioffset + icore;
    final double j = joffset + jcore;

    /// using _reusableVector
    /// so we don't have to make new Vector2 every time called
    /// but therefore must instantly consume the output as it may change
    assert(blockWidth != 0); //i.e. not set yet
    return output..setValues(
      (j + 1 / 2 - _layout.lengthH / 2) * blockWidth,
      (i + 1 / 2 - _layout.length / 2) * blockWidth,
    );
  }

  Vector2 _vectorOfMazeTile(Tile tile, {Vector2? output}) {
    final Vector2 out = output ?? Vector2.zero();
    final (int i, int j) = _layout.ijOfMazeTile(tile);
    return locationOfIJ(i, j, ioffset: 0.5, output: out);
  }

  /// Returns the starting position for a ghost based on its ID.
  Vector2 ghostStartForId(int idNum) {
    return _ghostStartForIdMap[idNum % 3]!;
  }

  Vector2 _ghostStartForId(int idNum) {
    return ghostStart.clone()..x += spriteWidth * (idNum % 3 - 1);
  }

  /// Returns the spawn position for a ghost based on its ID.
  Vector2 ghostSpawnForId(int idNum) {
    return idNum <= 2 ? ghostStartForId(idNum) : _cage;
  }

  /// Calculates the sprite width in screen pixels.
  int spriteWidthOnScreen(Vector2 size) {
    return (spriteWidth / worldSquareSize * min(size.x, size.y)).toInt();
  }
}
