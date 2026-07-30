/// Multiplier applied to all game sounds.
const double volumeScalar = 0.5;

/// Definitions of all sound effects used in the game.
enum SfxType {
  waka('pacman_waka_waka.mp3', 1.0),
  startMusic('pacman_beginning.mp3', 1.0),
  ghostsScared('ghosts_runaway.mp3', 1.0),
  endMusic('win.mp3', 1.0),
  eatGhost('eat_ghost.mp3', 1.0),
  pacmanDeath('pacman_death.mp3', 1.0),
  ghostsRoamingSiren('ghosts_siren.mp3', 0.0),
  silence('quiet.mp3', 0.01);

  const SfxType(this._filename, this._relativeVolume);

  // The base filename for the asset
  final String _filename;

  // The raw volume multiplier for this specific sound
  final double _relativeVolume;

  /// Returns the full asset path for the sound effect.
  String get filename => 'sfx/$_filename';

  bool get looping =>
      this == SfxType.ghostsRoamingSiren || this == SfxType.ghostsScared;

  bool get longSound =>
      looping || this == SfxType.startMusic || this == SfxType.endMusic;

  bool get toPlayInSoLoud => this != SfxType.silence;

  /// Returns the final calculated target volume.
  double get targetVolume => _relativeVolume * volumeScalar;
}
