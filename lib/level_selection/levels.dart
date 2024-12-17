import '../flame_game/pacman_game.dart';

class Levels {
  static const int firstRealLevel = 1;
  static const int max = 10;
  static const int min = -2;
  static const int levelToShowInstructions = defaultLevelNum;
  static const int playbackModeLevel = -4;
  static const int defaultLevelNum = playbackModeLevel;

  static const List<int> _ghostSpawnTimerLengthPattern = <int>[5, 3, 2, 1];

  static const double _levelSpeedFactor = 50 * (30 / flameGameZoom);

  double _tutorialFactor(int levelNum) {
    return levelNum >= 0
        ? 1
        : levelNum == min
            ? 0.5
            : 0.75;
  }

  GameLevel getLevel(int levelNum) {
    assert(levelNum <= max && levelNum >= min || levelNum == playbackModeLevel);
    bool playbackMode = false;
    if (levelNum == playbackModeLevel) {
      levelNum = firstRealLevel;
      playbackMode = true;
    }
    final GameLevel result = (
      number: playbackMode ? playbackModeLevel : levelNum,
      maxAllowedDeaths: 3,
      superPelletsEnabled: levelNum <= 1 ? true : false,
      multipleSpawningGhosts: levelNum <= 2 ? false : true,
      ghostSpawnTimerLength: levelNum <= 2
          ? -1
          : _ghostSpawnTimerLengthPattern[
              (levelNum - 3) % _ghostSpawnTimerLengthPattern.length],
      homingGhosts:
          levelNum <= 2 + _ghostSpawnTimerLengthPattern.length ? false : true,
      isTutorial: levelNum <= 0,
      levelSpeed: _levelSpeedFactor * _tutorialFactor(levelNum),
      ghostScaredTimeFactor: _tutorialFactor(levelNum),
      spinSpeedFactor: _tutorialFactor(levelNum),
      numStartingGhosts: levelNum >= 0
          ? 3
          : levelNum == min
              ? 1
              : (levelNum - 1) % 3 + 1,
      levelString:
          levelNum > 0 ? levelNum.toString() : "T${(levelNum - 1) % 4}",
      infLives: levelNum == min ? true : false,
    );
    return result;
  }
}

final Levels levels = Levels();

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
