import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../maze.dart';

const double _pelletScaleFactor = 0.4;

class Pellet extends CircleComponent with IgnoreEvents {
  Pellet(
      {required super.position,
      required this.pelletsRemainingNotifier,
      double radiusFactor = 1,
      double hitBoxRadiusFactor = 1})
      : super(
            radius: maze.spriteWidth / 2 * _pelletScaleFactor * radiusFactor,
            anchor: Anchor.center) {
    _hitbox = CircleHitbox(
      isSolid: true,
      collisionType: CollisionType.passive,
      radius: radius * hitBoxRadiusFactor,
      position: Vector2.all(radius),
      anchor: Anchor.center,
    );
  }

  late final CircleHitbox _hitbox;
  final ValueNotifier<int>
      pelletsRemainingNotifier; //passed in on creation of object rather than use slow to initialise HasGameReference for every single pellet

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_hitbox);
    //debugMode = true;
    pelletsRemainingNotifier.value += 1;
  }

  @override
  Future<void> onRemove() async {
    pelletsRemainingNotifier.value -= 1;
    super.onRemove();
  }
}
