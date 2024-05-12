const gameLevels = <GameLevel>[
  (
    number: 1,
    maxAllowedDeaths: 3,
    canSpawnTall: true,
  ),
  (
    number: 2,
  maxAllowedDeaths: 3,
    canSpawnTall: true,
  ),
];

typedef GameLevel = ({
  int number,
  int maxAllowedDeaths,
  bool canSpawnTall,
});
