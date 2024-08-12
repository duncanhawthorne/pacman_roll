import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

const int kResetPositionTimeMillis = 1000;

class MoveToPositionEffect extends MoveToEffect {
  MoveToPositionEffect(Vector2 destination, {onComplete})
      : super(
            destination,
            EffectController(
                duration: kResetPositionTimeMillis / 1000,
                curve: Curves.easeOut),
            onComplete: onComplete);
}
