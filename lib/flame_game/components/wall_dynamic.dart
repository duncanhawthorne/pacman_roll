import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../style/palette.dart';
import '../custom_game.dart';
import 'physics_ball.dart';
import 'scaled_body_render.dart';

final double _dynamicWallGravityScale = -1.0;

const bool movingWallsDamage = kDebugMode && false;

final Paint _movingWallPaint = Paint()..color = Palette.text.color;

/// A physical wall component that can move or be affected by physics.
class WallDynamic extends BodyComponent<CustomGame>
    with IgnoreEvents, ScaledBodyRender {
  WallDynamic({required super.shapeSpecs, required Vector2 position})
    : super(
        paint: _movingWallPaint,
        bodyDef: BodyDef(
          position: Vector2.zero()..setFrom(position),
          type: BodyType.dynamic,
          fixedRotation: !openSpaceMovement,
          gravityScale: _dynamicWallGravityScale,
        ),
      );

  @override
  final int priority = -3;

  late final Vector2 _size = _getSize();

  Vector2 _getSize() {
    final List<Vector2> v =
        (body.shapes.first.geometry as Polygon).points ?? <Vector2>[];
    final Iterable<double> xs = v.map((Vector2 element) => element.x);
    final Iterable<double> ys = v.map((Vector2 element) => element.y);
    final double minX = xs.reduce(min);
    final double maxX = xs.reduce(max);
    final double minY = ys.reduce(min);
    final double maxY = ys.reduce(max);
    return Vector2(maxX - minX, maxY - minY);
  }

  // ignore: unused_field
  late final RectangleHitbox _hitbox1 = RectangleHitbox(
    isSolid: true,
    size: _size * 0.65,
    collisionType: CollisionType.passive,
    anchor: Anchor.center,
  );

  late final RectangleHitbox _hitbox2 = RectangleHitbox(
    isSolid: true,
    size: _size * 0.65,
    collisionType: CollisionType.passive,
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (movingWallsDamage) {
      //add(_hitbox1); //parent?.add(_hitbox);
      parent?.add(_hitbox2);

      //_hitbox1.debugMode = true;
      //_hitbox1.debugColor = Colors.green;
      //_hitbox2.debugMode = true;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (movingWallsDamage) {
      _hitbox2.position.setFrom(position);
    }
  }
}
