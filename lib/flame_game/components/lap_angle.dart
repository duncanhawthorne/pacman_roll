import 'dart:core';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/foundation.dart';

import '../effects/rotate_effect.dart';
import '../pacman_world.dart';
import 'ghost.dart';
import 'sprite_character.dart';

const bool enableRotationRaceMode = kDebugMode && false;

mixin LapAngle on SpriteAnimationGroupComponent<CharacterState> {
  late double _lapAngleLast;
  double lapAngleProgress = 0;

  double _getLapAngle() {
    return position.screenAngle();
  }

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
    _updateLapAngle();
    super.update(dt);
  }
}

double getRaceProgress(PacmanWorld world) {
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
