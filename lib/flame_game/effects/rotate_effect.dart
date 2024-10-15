import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/animation.dart';

import 'move_to_effect.dart';

void resetSlideAngle(Component component, {Function()? onComplete}) {
  assert(component is PositionComponent || component is Viewfinder);
  if (component is PositionComponent) {
    component
      ..angle = smallAngle(component.angle)
      ..add(_rotateToAngleEffect(0, onComplete: onComplete));
  }
  if (component is Viewfinder) {
    component
      ..angle = smallAngle(component.angle)
      ..add(_rotateToAngleEffect(0, onComplete: onComplete));
  }
}

Effect _rotateToAngleEffect(double angle, {Function()? onComplete}) {
  //Should be able to do this by extending the class
  //would then integrate smallAngle function inside the class itself
  return RotateEffect.to(
      angle,
      EffectController(
          duration: kResetPositionTimeMillis / 1000, curve: Curves.easeOut),
      onComplete: onComplete);
}

double smallAngle(double angleDelta) {
  //produces number between -tau / 2 and +tau / 2
  //avoids +2*pi-delta jump when go around the circle, instead give -delta
  angleDelta = angleDelta % tau;
  return angleDelta > tau / 2 ? angleDelta - tau : angleDelta;
}
