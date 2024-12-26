List<String> soundTypeToFilename(SfxType type) => switch (type) {
      SfxType.ghostsScared => const <String>['ghosts_runaway.mp3'],
      SfxType.endMusic => const <String>['win.mp3'],
      SfxType.eatGhost => const <String>['eat_ghost.mp3'],
      SfxType.pacmanDeath => const <String>['pacman_death.mp3'],
      SfxType.waka => const <String>['pacman_waka_waka.mp3'],
      SfxType.startMusic => const <String>['pacman_beginning.mp3'],
      SfxType.ghostsRoamingSiren => const <String>['ghosts_siren.mp3'],
      SfxType.silence => const <String>['silence.mp3'],
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
