import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

List<Component> screenEdgeBoundaries(CameraComponent camera) {
  final Rect visibleRect = camera.visibleWorldRect;
  final Vector2 topLeft = visibleRect.topLeft.toVector2();
  final Vector2 topRight = visibleRect.topRight.toVector2();
  final Vector2 bottomRight = visibleRect.bottomRight.toVector2();
  final Vector2 bottomLeft = visibleRect.bottomLeft.toVector2();

  return [
    Line(topLeft, topRight),
    Line(topRight, bottomRight),
    Line(bottomLeft, bottomRight),
    Line(topLeft, bottomLeft),
  ];
}

class Line extends BodyComponent {
  //with CollisionCallbacks
  final Vector2 _start;
  final Vector2 _end;

  @override
  // ignore: overridden_fields
  final renderBody =
      false; //hide walls so replaced by bitmap background with the same visual meaning

  Line(this._start, this._end);

  @override
  Body createBody() {
    final shape = EdgeShape()..set(_start, _end);
    final fixtureDef = FixtureDef(shape, friction: 0.1, restitution: 0.0);
    final bodyDef = BodyDef(position: Vector2.zero());
    //final renderBody = false;
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}
