const gameLevels = <GameLevel>[
  (
    number: 1,
    maxAllowedDeaths: 3,
    superPelletsEnabled: true,
    multipleSpawningGhosts: false,
    ghostSpwanTimerLength: -1,
  ),
  (
    number: 2,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: false,
    ghostSpwanTimerLength: -1,
  ),
  (
    number: 3,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpwanTimerLength: 5,
  ),
  (
    number: 4,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpwanTimerLength: 3,
  ),
  (
    number: 5,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpwanTimerLength: 2,
  ),
  (
    number: 6,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpwanTimerLength: 1,
  ),
];

typedef GameLevel = ({
  int number,
  int maxAllowedDeaths,
  bool superPelletsEnabled,
  bool multipleSpawningGhosts,
  int ghostSpwanTimerLength,
});
