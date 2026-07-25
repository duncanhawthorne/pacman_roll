import '../flame_game/custom_game.dart';

/// Manages the configuration of different game levels.
class Levels {
  static const int firstRealLevel = 1;
  static const int maxLevel = 10;
  static const int minLevel = 0;
  static const int levelToShowInstructions = defaultLevelNum;
  static const int playbackModeLevel = -4;
  static const int defaultLevelNum = playbackModeLevel;

  static const List<int> _ghostSpawnTimerLengthPattern = <int>[5, 3, 2, 1];

  static const int levelSpeedPureScale = 50;
  static const double _levelSpeedFactor = levelSpeedPureScale * mapSizeScale;

  double _tutorialFactor(int levelNum) {
    return levelNum >= 1
        ? 1
        : levelNum == minLevel
        ? 0.75
        : 0.75; //not possible
  }

  /// Returns the [GameLevel] configuration for a specific level number.
  GameLevel getLevel(int levelNum) {
    final GameLevel result = (
      number: levelNum,
      maxAllowedDeaths: 3,
      superPelletsEnabled: levelNum <= 1 ? true : false,
      multipleSpawningGhosts: levelNum <= 2 ? false : true,
      ghostSpawnTimerLength: levelNum <= 2
          ? -1
          : _ghostSpawnTimerLengthPattern[(levelNum - 3) %
                _ghostSpawnTimerLengthPattern.length],
      homingGhosts: levelNum <= 2 + _ghostSpawnTimerLengthPattern.length
          ? false
          : true,
      isTutorial: levelNum <= 0,
      levelSpeed: _levelSpeedFactor * _tutorialFactor(levelNum),
      ghostScaredTimeFactor: _tutorialFactor(levelNum),
      spinSpeedFactor: _tutorialFactor(levelNum),
      numStartingGhosts: 3,
      levelString: levelNum > 0
          ? "L$levelNum"
          : "Tutorial", //${levelNum - minLevel + 1}",
      infLives: levelNum <= 0 ? true : false,
    );
    return result;
  }
}

/// Global instance of the level manager.
final Levels levels = Levels();

/// Type definition for a level's configuration properties.
typedef GameLevel = ({
  int number,
  int maxAllowedDeaths,
  bool superPelletsEnabled,
  bool multipleSpawningGhosts,
  int ghostSpawnTimerLength,
  bool homingGhosts,
  bool isTutorial,
  double levelSpeed,
  double ghostScaredTimeFactor,
  double spinSpeedFactor,
  int numStartingGhosts,
  String levelString,
  bool infLives,
});
