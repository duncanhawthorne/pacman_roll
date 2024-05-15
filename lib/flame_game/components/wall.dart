import 'package:flame_forge2d/flame_forge2d.dart';
import '../helper.dart';

class MazeWallRectangleGround extends BodyComponent {
  final Vector2 _position;
  final double width;
  final double height;

  MazeWallRectangleGround(this._position, this.width, this.height);

  @override
  Body createBody() {
    final shape = PolygonShape();
    paint = blueMazePaint;

    final List<Vector2> vertices = [
      Vector2(0, 0),
      Vector2(width, 0),
      Vector2(width, height),
      Vector2(0, height),
    ];

    shape.set(vertices);
    final fixtureDef = FixtureDef(shape);

    final bodyDef = BodyDef(
        type: BodyType.static,
        position: _position - Vector2(width / 2, height / 2));
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}

class MazeWallCircleGround extends BodyComponent {
  final Vector2 _position;
  final double _radius;

  MazeWallCircleGround(this._position, this._radius);

  @override
  Body createBody() {
    final shape = CircleShape();
    paint = blueMazePaint;

    shape.radius = _radius;
    final fixtureDef = FixtureDef(shape);

    final bodyDef = BodyDef(type: BodyType.static, position: _position);
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}

class Wall extends BodyComponent {
  //with CollisionCallbacks
  final Vector2 _start;
  final Vector2 _end;

  @override
  // ignore: overridden_fields
  final renderBody =
      false; //hide walls so replaced by bitmap background with the same visual meaning

  Wall(this._start, this._end);

  @override
  Body createBody() {
    final shape = EdgeShape()..set(_start, _end);
    final fixtureDef = FixtureDef(shape, friction: 0.1, restitution: 0.0);
    final bodyDef = BodyDef(position: Vector2.zero());
    //final renderBody = false;
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}
