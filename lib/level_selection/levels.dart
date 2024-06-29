const gameLevels = <GameLevel>[
  (
    number: 1,
    maxAllowedDeaths: 3,
    superPelletsEnabled: true,
  ),
  (
    number: 2,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
  ),
];

typedef GameLevel = ({
  int number,
  int maxAllowedDeaths,
  bool superPelletsEnabled
});
