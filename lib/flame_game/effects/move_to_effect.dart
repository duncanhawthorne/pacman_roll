import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../components/ghost.dart';

class MoveToPositionEffect extends MoveToEffect {
  MoveToPositionEffect(Vector2 destination, {onComplete})
      : super(
            destination,
            EffectController(
                duration: kGhostResetTimeMillis / 1000, curve: Curves.easeOut),
            onComplete: onComplete);
}
