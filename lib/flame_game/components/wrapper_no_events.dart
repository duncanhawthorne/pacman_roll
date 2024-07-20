import 'package:flame/components.dart';

class WrapperNoEvents extends PositionComponent with IgnoreEvents {}

class PelletWrapper extends WrapperNoEvents {
  @override
  final priority = -2;
}

class WallWrapper extends WrapperNoEvents {}

class CharacterWrapper extends WrapperNoEvents {}
