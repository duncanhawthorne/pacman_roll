const gameLevels = <GameLevel>[
  (
    number: 1,
    maxAllowedDeaths: 3,
    superPelletsEnabled: true,
    multipleSpawningGhosts: false,
  ),
  (
    number: 2,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: false,
  ),
  (
    number: 3,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
  ),
];

typedef GameLevel = ({
  int number,
  int maxAllowedDeaths,
  bool superPelletsEnabled,
  bool multipleSpawningGhosts
});
