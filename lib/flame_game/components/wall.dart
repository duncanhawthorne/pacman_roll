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

class WallRectangleVisual extends RectangleComponent with IgnoreEvents {
  WallRectangleVisual(
      {required super.position, required double width, required double height})
      : super(
            size: Vector2(width, height),
            anchor: Anchor.center,
            paint: _wallVisualPaint);
}

class WallCircleVisual extends CircleComponent with IgnoreEvents {
  WallCircleVisual({required super.radius, required super.position})
      : super(anchor: Anchor.center, paint: _wallVisualPaint);
}

// ignore: always_specify_types
class WallGround extends BodyComponent with IgnoreEvents {
  WallGround({required super.fixtureDefs})
      : super(paint: _wallGroundPaint, bodyDef: BodyDef(type: BodyType.static));

  @override
  final int priority = -3;
}
