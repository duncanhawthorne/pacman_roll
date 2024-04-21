const gameLevels = <GameLevel>[
  (
    number: 1,
    winScore: 300,
    canSpawnTall: true,
  ),
  (
    number: 2,
    winScore: 300,
    canSpawnTall: true,
  ),
];

typedef GameLevel = ({
  int number,
  int winScore,
  bool canSpawnTall,
});
