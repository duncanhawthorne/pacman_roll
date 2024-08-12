import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import 'move_to_effect.dart';

class RotateByAngleEffect extends RotateEffect {
  RotateByAngleEffect(double angle, {onComplete})
      : super.by(
            angle,
            EffectController(
                duration: kResetPositionTimeMillis / 1000,
                curve: Curves.easeOut),
            onComplete: onComplete);
}
