List<String> soundTypeToFilename(SfxType type) {
  switch (type) {
    case SfxType.ghostsScared:
      return const [
        'ghosts_runaway.mp3',
      ];
    case SfxType.clearedBoard:
      return const [
        'win.mp3',
      ];
    case SfxType.eatGhost:
      return const [
        'eat_ghost.mp3'
        //'hit2.mp3',
      ];
    case SfxType.pacmanDeath:
      return const [
        'pacman_death.mp3'
        //'damage2.mp3',
      ];
    case SfxType.wa:
      return const [
        'pacman_waka_wa.mp3',
      ];
    case SfxType.ka:
      return const [
        'pacman_waka_ka.mp3',
      ];
    case SfxType.startMusic:
      return const [
        'pacman_beginning.mp3',
      ];
    case SfxType.buttonTap:
      return const [
        'click1.mp3',
        'click2.mp3',
        'click3.mp3',
        'click4.mp3',
      ];
  }
}

/// Allows control over loudness of different SFX types.
double soundTypeToVolume(SfxType type) {
  switch (type) {
    case SfxType.wa:
    case SfxType.ka:
    case SfxType.startMusic:
    case SfxType.ghostsScared:
    case SfxType.clearedBoard:
    case SfxType.pacmanDeath:
    case SfxType.eatGhost:
      return 0.4;
    case SfxType.buttonTap:
      return 1.0;
  }
}

enum SfxType {
  wa,
  ka,
  startMusic,
  ghostsScared,
  clearedBoard,
  eatGhost,
  pacmanDeath,
  buttonTap,
}
