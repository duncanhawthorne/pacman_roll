import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../maze.dart';

class Pellet extends CircleComponent with IgnoreEvents {
  Pellet(
      {required super.position,
      required this.pelletsRemainingNotifier,
      double radiusFactor = 1,
      this.hitBoxRadiusFactor = 1})
      : super(
            radius:
                maze.spriteWidth / 2 * Maze.pelletScaleFactor * radiusFactor,
            anchor: Anchor.center);

  final double hitBoxRadiusFactor;
  final ValueNotifier<int> pelletsRemainingNotifier;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(
      isSolid: true,
      collisionType: CollisionType.passive,
      radius: radius * hitBoxRadiusFactor,
      position: Vector2.all(radius),
      anchor: Anchor.center,
    ));
    //debugMode = true;
    pelletsRemainingNotifier.value += 1;
  }

  @override
  Future<void> onRemove() async {
    pelletsRemainingNotifier.value -= 1;
    super.onRemove();
  }
}
