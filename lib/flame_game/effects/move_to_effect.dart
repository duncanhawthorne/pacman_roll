import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

const int kResetPositionTimeMillis = 1000;

class MoveToPositionEffect extends MoveToEffect {
  MoveToPositionEffect(
    Vector2 destination, {
    Function()? onComplete,
    double duration = kResetPositionTimeMillis / 1000,
  }) : super(
         destination,
         EffectController(duration: duration, curve: Curves.easeOut),
         onComplete: onComplete,
       );
}
