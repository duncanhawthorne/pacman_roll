final gameLevels = List.generate(10 + 1, (index) => _gameLevelAtIndex(index));

final _ghostSpawnTimerLengthPattern = {0: 5, 1: 3, 2: 2, 3: 1};

GameLevel _gameLevelAtIndex(index) {
  GameLevel result = (
    number: index,
    maxAllowedDeaths: index <= 0 ? 5 : 3,
    superPelletsEnabled: index <= 1 ? true : false,
    multipleSpawningGhosts: index <= 2 ? false : true,
    ghostSpawnTimerLength:
        index <= 2 ? -1 : _ghostSpawnTimerLengthPattern[(index - 3) % 4]!,
    homingGhosts: index <= 6 ? false : true,
  );
  return result;
}

typedef GameLevel = ({
  int number,
  int maxAllowedDeaths,
  bool superPelletsEnabled,
  bool multipleSpawningGhosts,
  int ghostSpawnTimerLength,
  bool homingGhosts,
});

GameLevel levelSelect(int levelNum) {
  return gameLevels.firstWhere((level) => level.number == levelNum,
      orElse: () =>
          gameLevels.firstWhere((level) => level.number == defaultLevelNum));
}

bool isTutorialLevel(GameLevel level) {
  return level.number == tutorialLevelNum;
}

int maxLevel() {
  return gameLevels.last.number;
}

const defaultLevelNum = 1;
const tutorialLevelNum = 0;
