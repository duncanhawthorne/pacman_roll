import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../../style/palette.dart';

final Paint _blackBackgroundPaint = Paint()
//..filterQuality = FilterQuality.none
////..color = Color.fromARGB(50, 100, 100, 100)
//..isAntiAlias = false
  ..color = Palette.black;
final Paint _blueMazePaint = Paint()
//..filterQuality = FilterQuality.none
////..color = Color.fromARGB(50, 100, 100, 100)
//..isAntiAlias = false
  ..color = Palette.blueMaze;

class MazeWallRectangleVisual extends RectangleComponent with IgnoreEvents {
  MazeWallRectangleVisual(
      {required super.position, required width, required height})
      : super(
            size: Vector2(width, height),
            anchor: Anchor.center,
            paint: _blackBackgroundPaint);
}

class MazeVisualBlockingBar extends MazeWallRectangleVisual {
  MazeVisualBlockingBar(
      {required super.position, required super.width, required super.height});
  @override
  final priority = 1000;
}

class MazeWallCircleVisual extends CircleComponent with IgnoreEvents {
  MazeWallCircleVisual({required super.radius, required super.position})
      : super(anchor: Anchor.center, paint: _blackBackgroundPaint); //NOTE BLACK
}

class MazeWallRectangleGround extends BodyComponent with IgnoreEvents {
  @override
  final Vector2 position;
  final double width;
  final double height;

  MazeWallRectangleGround(
      {required this.position, required this.width, required this.height});

  @override
  // ignore: overridden_fields
  final renderBody = true;

  @override
  final priority = -2;

  @override
  Body createBody() {
    final shape = PolygonShape();
    paint = _blueMazePaint;
    shape.setAsBoxXY(width / 2, height / 2);
    final fixtureDef = FixtureDef(shape);
    final bodyDef = BodyDef(type: BodyType.static, position: position);
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}

class MazeWallCircleGround extends BodyComponent with IgnoreEvents {
  @override
  final Vector2 position;
  final double radius;

  MazeWallCircleGround({required this.position, required this.radius});

  @override
  // ignore: overridden_fields
  final renderBody = true;

  @override
  final priority = -2;

  @override
  Body createBody() {
    final shape = CircleShape();
    paint = _blueMazePaint;

    shape.radius = radius;
    final fixtureDef = FixtureDef(shape);

    final bodyDef = BodyDef(type: BodyType.static, position: position);
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}
