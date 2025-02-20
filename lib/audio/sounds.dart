String _soundTypeToFilename(SfxType type) => switch (type) {
  SfxType.ghostsScared => 'ghosts_runaway.mp3',
  SfxType.endMusic => 'win.mp3',
  SfxType.eatGhost => 'eat_ghost.mp3',
  SfxType.pacmanDeath => 'pacman_death.mp3',
  SfxType.waka => 'pacman_waka_waka.mp3',
  SfxType.startMusic => 'pacman_beginning.mp3',
  SfxType.ghostsRoamingSiren => 'ghosts_siren.mp3',
  SfxType.silence => 'quiet.mp3',
};

const double volumeScalar = 0.5;

/// Allows control over loudness of different SFX types.
double _soundTypeToVolume(SfxType type) {
  switch (type) {
    case SfxType.waka:
    case SfxType.startMusic:
    case SfxType.ghostsScared:
    case SfxType.endMusic:
    case SfxType.pacmanDeath:
    case SfxType.eatGhost:
      return 1 * volumeScalar;
    case SfxType.ghostsRoamingSiren:
      return 0 * volumeScalar;
    case SfxType.silence:
      return 0.01 * volumeScalar;
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

/// Extension to provide helper functions for SfxType
extension SfxTypeExtension on SfxType {
  String get filename => "sfx/${_soundTypeToFilename(this)}";

  double get targetVolume => _soundTypeToVolume(this);
}
