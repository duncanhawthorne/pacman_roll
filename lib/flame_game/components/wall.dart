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

class MazeWallRectangleVisual extends RectangleComponent with IgnoreEvents {
  MazeWallRectangleVisual(
      {required super.position, required double width, required double height})
      : super(
            size: Vector2(width, height),
            anchor: Anchor.center,
            paint: _wallVisualPaint);
}

class MazeVisualBlockingBar extends MazeWallRectangleVisual {
  MazeVisualBlockingBar(
      {required super.position, required super.width, required super.height});
  @override
  final int priority = 1000;
}

class MazeWallCircleVisual extends CircleComponent with IgnoreEvents {
  MazeWallCircleVisual({required super.radius, required super.position})
      : super(anchor: Anchor.center, paint: _wallVisualPaint);
}

// ignore: always_specify_types
class MazeWallRectangleGround extends BodyComponent with IgnoreEvents {
  MazeWallRectangleGround(
      {required this.position, required this.width, required this.height});
  @override
  final Vector2 position;
  final double width;
  final double height;

  @override
  // ignore: overridden_fields
  final bool renderBody = true;

  @override
  final int priority = -2;

  @override
  Body createBody() {
    final PolygonShape shape = PolygonShape();
    paint = _wallGroundPaint;
    shape.setAsBoxXY(width / 2, height / 2);
    final FixtureDef fixtureDef = FixtureDef(shape);
    final BodyDef bodyDef = BodyDef(type: BodyType.static, position: position);
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}

// ignore: always_specify_types
class MazeWallCircleGround extends BodyComponent with IgnoreEvents {
  MazeWallCircleGround({required this.position, required this.radius});
  @override
  final Vector2 position;
  final double radius;

  @override
  // ignore: overridden_fields
  final bool renderBody = true;

  @override
  final int priority = -2;

  @override
  Body createBody() {
    final CircleShape shape = CircleShape();
    paint = _wallGroundPaint;

    shape.radius = radius;
    final FixtureDef fixtureDef = FixtureDef(shape);

    final BodyDef bodyDef = BodyDef(type: BodyType.static, position: position);
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}
