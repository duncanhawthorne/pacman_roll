import 'dart:ui';

import 'package:flame_forge2d/body_component.dart';

import '../../utils/constants.dart';
import '../custom_game.dart';
import 'physics_ball.dart';

/// Mixin to handle coordinate scaling when rendering physics bodies.
mixin ScaledBodyRender on BodyComponent<CustomGame> {
  @override
  void render(Canvas canvas) {
    if (kPhysicsScaleLockedAtOne) {
      super.render(canvas);
      return;
    }

    canvas
      ..save()
      ..rotate(-body.angle)
      ..translate(-position.x, -position.y)
      ..scale(invPhysicsScale)
      ..translate(position.x, position.y)
      ..rotate(body.angle);
    super.render(canvas);
    canvas.restore();

    if (drawDebugBoxes) {
      super.render(canvas);
    }
  }
}
