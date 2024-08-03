import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../components/ghost.dart';

class RotateByAngleEffect extends RotateEffect {
  RotateByAngleEffect(double angle, {onComplete})
      : super.by(
            angle,
            EffectController(
                duration: kGhostResetTimeMillis / 1000, curve: Curves.easeOut),
            onComplete: onComplete);
}
