
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'components/wall.dart';
import 'constants.dart';
import'dart:math';

List<Component> createBoundaries(CameraComponent camera) {
  final Rect visibleRect = camera.visibleWorldRect;
  final Vector2 topLeft = visibleRect.topLeft.toVector2();
  final Vector2 topRight = visibleRect.topRight.toVector2();
  final Vector2 bottomRight = visibleRect.bottomRight.toVector2();
  final Vector2 bottomLeft = visibleRect.bottomLeft.toVector2();

  return [
    Wall(topLeft, topRight),
    Wall(topRight, bottomRight),
    Wall(bottomLeft, bottomRight),
    Wall(topLeft, bottomLeft),
  ];
}

Vector2 getTarget(Vector2 localPosition, Vector2 size) {
  return Vector2(
      min(size.x / dzoom / 2, max(-size.x / dzoom / 2, localPosition.x)),
      min(size.y / dzoom / 2 * 10 / 10,
          max(size.y / dzoom / 2 * 0 / 10, localPosition.y)));
}