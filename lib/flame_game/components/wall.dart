import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/collisions.dart';

class Wall extends BodyComponent with CollisionCallbacks {
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
