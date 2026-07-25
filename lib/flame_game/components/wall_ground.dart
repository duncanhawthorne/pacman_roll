import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../../style/palette.dart';
import '../custom_game.dart';
import 'scaled_body_render.dart';

final Paint _wallGroundPaint = Paint()..color = Palette.seed.color;

final BodyDef _staticBodyDef = BodyDef(type: BodyType.static);

/// Physical body representing the combined static walls of the maze.
class WallGround extends BodyComponent<CustomGame>
    with IgnoreEvents, ScaledBodyRender {
  WallGround({required super.shapeSpecs})
    : super(paint: _wallGroundPaint, bodyDef: _staticBodyDef);

  @override
  final int priority = -3;
}
