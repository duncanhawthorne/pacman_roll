String soundTypeToFilename(SfxType type) => switch (type) {
      SfxType.ghostsScared => 'ghosts_runaway.mp3',
      SfxType.endMusic => 'win.mp3',
      SfxType.eatGhost => 'eat_ghost.mp3',
      SfxType.pacmanDeath => 'pacman_death.mp3',
      SfxType.waka => 'pacman_waka_waka.mp3',
      SfxType.startMusic => 'pacman_beginning.mp3',
      SfxType.ghostsRoamingSiren => 'ghosts_siren.mp3',
      SfxType.silence => 'silence.mp3',
    };

const double volumeScalar = 0.5;

/// Allows control over loudness of different SFX types.
double soundTypeToVolume(SfxType type) {
  switch (type) {
    case SfxType.waka:
    case SfxType.startMusic:
    case SfxType.ghostsScared:
    case SfxType.endMusic:
    case SfxType.pacmanDeath:
    case SfxType.eatGhost:
      return 1 * volumeScalar;
    case SfxType.ghostsRoamingSiren:
      return 0;
    case SfxType.silence:
      return 0.3;
  }
}

enum SfxType {
  waka,
  startMusic,
  ghostsScared,
  endMusic,
  eatGhost,
  pacmanDeath,
  ghostsRoamingSiren,
  silence,
}
