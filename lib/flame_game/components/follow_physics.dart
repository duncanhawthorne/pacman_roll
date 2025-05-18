import 'dart:core';

import 'package:flame/components.dart';

import '../pacman_world.dart';
import 'game_character.dart';
import 'physics_ball.dart';

class Physics extends Component with HasWorldReference<PacmanWorld> {
  Physics({required this.owner});

  late final GameCharacter owner;
  static final Vector2 _reusableVector = Vector2.zero();

  late final PhysicsBall _ball = PhysicsBall(
    position: owner.position,
    radius: owner.radius,
    velocity: owner.velocity,
    angularVelocity: owner.angularVelocity,
    damping: 1 - owner.friction,
    density: owner.density,
    active: true,
    //FIXME could set this
    owner: owner,
  );

  double get _spinParity =>
      _ballVel.x.abs() > _ballVel.y.abs()
          ? _gravitySign.y * _ballVel.x.sign
          : -_gravitySign.x * _ballVel.y.sign;

  late final bool _freeRotation = true;

  double get speed => !_ball.isMounted ? 0 : _ballVel.length;

  late final double _initialRadius = owner.size.x / 2;

  void setBallRadius(double x) {
    if (isMounted && _ball.isMounted) {
      _ball.radius = x;
    }
  }

  late final Vector2 _gravitySign = world.gravitySign;

  Vector2 get _ballPos =>
      spriteVsPhysicsScaleConstant ? _ballPosUnscaled : _reusableVector
        ..setFrom(_ballPosUnscaled)
        ..scale(spriteVsPhysicsScale);
  late final Vector2 _ballPosUnscaled = _ball.position;
  Vector2 get _ballVel =>
      spriteVsPhysicsScaleConstant ? _ballVelUnscaled : _reusableVector
        ..setFrom(_ballVelUnscaled)
        ..scale(spriteVsPhysicsScale);
  late final Vector2 _ballVelUnscaled = _ball.body.linearVelocity;

  Future<void> _initaliseFromOwner() async {
    assert(_ball.isLoaded);
    _ball.position = owner.position;
    _ball.velocity = owner.velocity;
    _ball.radius = owner.radius;
    _ball.body.angularVelocity = owner.angularVelocity;
  }

  void initaliseFromOwnerAndSetDynamic() {
    assert(_ball.isLoaded);
    _initaliseFromOwner();
    _ball.setDynamic();
  }

  void _oneFrameOfPhysics(double dt) {
    if (!isMounted || !_ball.isMounted || !_ball.isLoaded) {
      return;
    }
    if (owner.canAccelerate) {
      _ball.acceleration = owner.acceleration;
    }
    owner.position = _ballPos;
    owner.velocity = _ballVel;
    owner.angularVelocity = _ball.body.angularVelocity;
    if (openSpaceMovement) {
      if (_freeRotation) {
        owner.angle = _ball.angle;
      }
    } else {
      owner.angle += speed * dt / _initialRadius * _spinParity;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (owner.state != PhysicsState.full) {
      deactivate();
      return;
    }
    _oneFrameOfPhysics(dt);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    if (owner.isClone) {
      return;
    }
    await world.add(_ball);
    await _ball.mounted;
  }

  void removalActions() {
    _ball.removeFromParent();
    //world.destroyBody(_ball.body); //FIXME investigate
  }

  void deactivate() {
    if (owner.isRemoving) {
      return;
    }
    assert(_ball.isLoaded);
    _ball.setStatic();
  }

  @override
  void removeFromParent() {
    removalActions();
    super.removeFromParent(); //async
  }

  @override
  Future<void> onRemove() async {
    removalActions();
    super.onRemove();
  }
}
