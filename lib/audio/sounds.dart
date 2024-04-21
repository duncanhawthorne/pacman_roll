List<String> soundTypeToFilename(SfxType type) {
  switch (type) {
    case SfxType.jump:
      return const [
        'ghosts_runaway.mp3',
      ];
    case SfxType.doubleJump:
      return const [
        'double_jump1.mp3',
      ];
    case SfxType.hit:
      return const [
        'eat_ghost.mp3'
        //'hit2.mp3',
      ];
    case SfxType.damage:
      return const [
        'pacman_death.mp3'
        //'damage2.mp3',
      ];
    case SfxType.score:
      return const [
        'pacman_waka_ka.mp3',
        //'pacman_waka_wa.mp3',
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
    case SfxType.score:
    case SfxType.jump:
    case SfxType.doubleJump:
    case SfxType.damage:
    case SfxType.hit:
      return 0.4;
    case SfxType.buttonTap:
      return 1.0;
  }
}

enum SfxType {
  score,
  jump,
  doubleJump,
  hit,
  damage,
  buttonTap,
}
