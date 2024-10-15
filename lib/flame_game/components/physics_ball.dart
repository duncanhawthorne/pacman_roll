import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../maze.dart';

const bool _useForgePhysicsBallRotation = false;
const bool _instantSetPosition = true;
const double _radiusScaleFactor = 0.99;

// ignore: always_specify_types
class PhysicsBall extends BodyComponent with IgnoreEvents {
  PhysicsBall({
    required Vector2 position,
    double? radius,
  }) : super(
            fixtureDefs: <FixtureDef>[
              FixtureDef(
                CircleShape()
                  ..radius =
                      radius ?? maze.spriteWidth / 2 * _radiusScaleFactor,
                restitution: 0.0,
                friction: _useForgePhysicsBallRotation ? 1 : 0,
                userData: PhysicsBall,
              ),
            ],
            bodyDef: BodyDef(
              angularDamping: _useForgePhysicsBallRotation ? 0.1 : 0.1,
              position: position,
              type: BodyType.dynamic,
              userData: PhysicsBall,
            ));

  @override
  // ignore: overridden_fields
  final bool renderBody = false;

  double get speed => body.linearVelocity.length;

  set velocity(Vector2 vel) => body.linearVelocity.setFrom(vel);

  set position(Vector2 pos) => <void>{
        _instantSetPosition ? _setPositionNow(pos) : _setPositionNextFrame(pos)
      };

  final Vector2 _oneTimeManualPosition = Vector2(0, 0);
  bool _oneTimeManualPositionSet = false;

  void _setPositionNextFrame(Vector2 pos) {
    assert(!_instantSetPosition);
    _oneTimeManualPosition.setFrom(pos);
    _oneTimeManualPositionSet = true;
  }

  void _setPositionNow(Vector2 pos) {
    body.setTransform(pos, 0); //realCharacter.angle
  }

  bool _subConnectedBall = true;

  void setDynamic() {
    body
      ..setType(BodyType.dynamic)
      ..setActive(true);
    _subConnectedBall = true;
  }

  void setStatic() {
    if (isMounted && body.isActive) {
      // avoid crashes if body not yet initialised
      // Probably about to remove ball anyway
      body
        ..setType(BodyType.static)
        ..setActive(false);
    }
    _subConnectedBall = false;
  }

  final Vector2 _oneTimeManualPortalPosition = Vector2.zero();
  void _moveThroughPipePortal() {
    if (_subConnectedBall) {
      if (position.x.abs() > maze.mazeWidth / 2 ||
          position.y.abs() > maze.mazeHeight / 2) {
        _oneTimeManualPortalPosition
          ..x = _smallMod(position.x, maze.mazeWidth)
          ..y = _smallMod(position.y, maze.mazeHeight);
        position = _oneTimeManualPortalPosition;
      }
    }
  }

  @override
  void update(double dt) {
    _moveThroughPipePortal();
    if (!_instantSetPosition && _oneTimeManualPositionSet) {
      _setPositionNow(_oneTimeManualPosition);
      _oneTimeManualPositionSet = false;
    }
    super.update(dt);
  }
}

double _smallMod(double position, double mod) {
  //produces number between -mod / 2 and +mod / 2
  position = position % mod;
  return position > mod / 2 ? position - mod : position;
}
