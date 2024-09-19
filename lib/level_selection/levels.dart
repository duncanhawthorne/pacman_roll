const gameLevels = <GameLevel>[
  (
    number: 0,
    maxAllowedDeaths: 5,
    superPelletsEnabled: true,
    multipleSpawningGhosts: false,
    ghostSpawnTimerLength: -1,
    homingGhosts: false,
  ),
  (
    number: 1,
    maxAllowedDeaths: 3,
    superPelletsEnabled: true,
    multipleSpawningGhosts: false,
    ghostSpawnTimerLength: -1,
    homingGhosts: false,
  ),
  (
    number: 2,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: false,
    ghostSpawnTimerLength: -1,
    homingGhosts: false,
  ),
  (
    number: 3,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpawnTimerLength: 5,
    homingGhosts: false,
  ),
  (
    number: 4,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpawnTimerLength: 3,
    homingGhosts: false,
  ),
  (
    number: 5,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpawnTimerLength: 2,
    homingGhosts: false,
  ),
  (
    number: 6,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpawnTimerLength: 1,
    homingGhosts: false,
  ),
  (
    number: 7,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpawnTimerLength: 5,
    homingGhosts: true,
  ),
  (
    number: 8,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpawnTimerLength: 3,
    homingGhosts: true,
  ),
  (
    number: 9,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpawnTimerLength: 2,
    homingGhosts: true,
  ),
  (
    number: 10,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpawnTimerLength: 1,
    homingGhosts: true,
  ),
];

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
