import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/geometry.dart';

import '../../utils/constants.dart';
import '../custom_world.dart';
import '../effects/rotate_effect.dart';
import 'ghost.dart';
import 'sprite_character.dart';

/// Mixin to track the cumulative angular progress of a character around the maze center.
mixin LapAngle on SpriteAnimationGroupComponent<CharacterState> {
  late double _lapAngleLast;
  double lapAngleProgress = 0;

  /// Returns the current angular position of the character relative to the center.
  double _getLapAngle() {
    return position.screenAngle();
  }

  /// Updates the cumulative lap progress by measuring the change in angular position.
  void _updateLapAngle() {
    if (!enableRotationRaceMode) {
      return;
    }
    lapAngleProgress += smallAngle(_getLapAngle() - _lapAngleLast);
    _lapAngleLast = _getLapAngle();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (enableRotationRaceMode) {
      _lapAngleLast = _getLapAngle();
    }
  }

  @override
  void update(double dt) {
    if (!enableRotationRaceMode) {
      super.update(dt);
      return;
    }
    _updateLapAngle();
    super.update(dt);
  }
}

/// Calculates the overall progress of the race by comparing Pacman's laps to the ghosts'.
double getRaceProgress(CustomWorld world) {
  assert(enableRotationRaceMode);
  if (!enableRotationRaceMode) {
    return 0;
  }
  if (world.pacmans.pacmanList.isEmpty || world.ghosts.ghostList.isEmpty) {
    return 0;
  }
  return 1 /
      tau *
      (world.pacmans.pacmanList[0].lapAngleProgress -
          world.ghosts.ghostList
              .map((Ghost ghost) => ghost.lapAngleProgress)
              .reduce(max));
}
