import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../style/palette.dart';
import 'physics_ball.dart';

final Paint _wallVisualPaint = Paint()..color = Palette.background.color;
final Paint _wallGroundPaint = Paint()..color = Palette.seed.color;
final Paint _movingWallPaint = Paint()..color = Palette.text.color;

//..filterQuality = FilterQuality.none
////..color = Color.fromARGB(50, 100, 100, 100)
//..isAntiAlias = false

final BodyDef _staticBodyDef = BodyDef(type: BodyType.static);

class WallRectangleVisual extends RectangleComponent with IgnoreEvents {
  WallRectangleVisual({required super.position, required super.size})
    : super(anchor: Anchor.center, paint: _wallVisualPaint);
}

class WallCircleVisual extends CircleComponent with IgnoreEvents {
  WallCircleVisual({required super.radius, required super.position})
    : super(anchor: Anchor.center, paint: _wallVisualPaint);
}

// ignore: always_specify_types
class WallGround extends BodyComponent with IgnoreEvents {
  WallGround({required super.fixtureDefs})
    : super(paint: _wallGroundPaint, bodyDef: _staticBodyDef);

  @override
  final int priority = -3;
}

final Vector2 _dynamicWallGravityScale = Vector2(-1, -1);

const bool movingWallsDamage = kDebugMode && false;

// ignore: always_specify_types
class WallDynamic extends BodyComponent with IgnoreEvents {
  WallDynamic({required super.fixtureDefs, required Vector2 position})
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
        (body.fixtures.first.shape as PolygonShape).vertices;
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
