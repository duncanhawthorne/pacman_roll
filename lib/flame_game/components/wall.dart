import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../../style/palette.dart';

final Paint _wallVisualPaint = Paint()
//..filterQuality = FilterQuality.none
////..color = Color.fromARGB(50, 100, 100, 100)
//..isAntiAlias = false
  ..color = Palette.background.color;
final Paint _wallGroundPaint = Paint()
//..filterQuality = FilterQuality.none
////..color = Color.fromARGB(50, 100, 100, 100)
//..isAntiAlias = false
  ..color = Palette.seed.color;
final Paint _movingWallPaint = Paint()
//..filterQuality = FilterQuality.none
////..color = Color.fromARGB(50, 100, 100, 100)
//..isAntiAlias = false
  ..color = Palette.text.color;

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

// ignore: always_specify_types
class WallDynamic extends BodyComponent with IgnoreEvents {
  WallDynamic({required super.fixtureDefs, required Vector2 position})
      : super(
            paint: _movingWallPaint,
            bodyDef: BodyDef(
                position: Vector2.zero()..setFrom(position),
                type: BodyType.dynamic,
                fixedRotation: true,
                gravityScale: _dynamicWallGravityScale));

  @override
  final int priority = -3;
}
