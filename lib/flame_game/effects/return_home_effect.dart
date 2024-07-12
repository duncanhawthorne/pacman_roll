import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../components/ghost.dart';

/// The [JumpEffect] is simply a [MoveByEffect] which has the properties of the
/// effect pre-defined.
class ReturnHomeEffect extends MoveToEffect {
  ReturnHomeEffect(Vector2 destination)
      : super(
            destination,
            EffectController(
                duration: kGhostResetTimeMillis / 1000, curve: Curves.linear));
}

class RotateHomeEffect extends RotateEffect {
  RotateHomeEffect(double destination)
      : super.by(
            destination,
            EffectController(
                duration: kGhostResetTimeMillis / 1000, curve: Curves.linear));
}

class RotateHomeEffectAndReset extends RotateEffect {
  RotateHomeEffectAndReset(double destination, {required onComplete})
      : super.by(
            destination,
            EffectController(
                duration: kGhostResetTimeMillis / 1000, curve: Curves.linear),
            onComplete: onComplete);
}
