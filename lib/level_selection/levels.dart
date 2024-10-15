class Levels {
  static const int tutorialLevelNum = 0;
  static const int firstRealLevel = 1;
  static const int max = 10;
  static const int levelToShowInstructions = defaultLevelNum;
  static const int defaultLevelNum = tutorialLevelNum;

  static const List<int> _ghostSpawnTimerLengthPattern = <int>[5, 3, 2, 1];

  GameLevel getLevel(int levelNum) {
    final GameLevel result = (
      number: levelNum,
      maxAllowedDeaths: levelNum <= 0 ? 5 : 3,
      superPelletsEnabled: levelNum <= 1 ? true : false,
      multipleSpawningGhosts: levelNum <= 2 ? false : true,
      ghostSpawnTimerLength: levelNum <= 2
          ? -1
          : _ghostSpawnTimerLengthPattern[
              (levelNum - 3) % _ghostSpawnTimerLengthPattern.length],
      homingGhosts:
          levelNum <= 2 + _ghostSpawnTimerLengthPattern.length ? false : true,
      isTutorial: levelNum == tutorialLevelNum,
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
});
