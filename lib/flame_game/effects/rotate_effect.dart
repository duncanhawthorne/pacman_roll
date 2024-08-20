import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import 'move_to_effect.dart';

/*
void _resetSlideAngle(PositionComponent component, {Function()? onComplete}) {
  component.angle = smallAngle(component.angle);
  component.add(RotateToAngleEffect(0, onComplete: onComplete));
}

 */

// ignore: non_constant_identifier_names
Effect RotateToAngleEffect(double angle, {Function()? onComplete}) {
  //Should be able to do this by extending the class
  //would then integrate smallAngle function inside the class itself
  return RotateEffect.to(
      angle,
      EffectController(
          duration: kResetPositionTimeMillis / 1000, curve: Curves.easeOut),
      onComplete: onComplete);
}
