import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

class NullEffect extends RotateEffect {
  NullEffect(int durationMillis, {Function()? onComplete})
    : super.by(
        0,
        EffectController(
          duration: durationMillis / 1000,
          curve: Curves.easeOut,
        ),
        onComplete: onComplete,
      );
}
