import 'package:flame/components.dart';

import '../../utils/helper.dart';
import '../custom_world.dart';
import 'game_character.dart';
import 'physics_ball.dart';
import 'removal_actions.dart';

/// A component that syncs a character's position and angle with its physical [PhysicsBall].
class Physics extends Component
    with HasWorldReference<CustomWorld>, RemovalActions, IgnoreEvents {
  Physics({required this.owner});

  @override
  final int priority = 1000;

  late final GameCharacter owner;
  static final Vector2 _reusableVector = Vector2.zero();

  late final PhysicsBall _ball = PhysicsBall(
    position: owner.position,
    radius: owner.radius,
    velocity: owner.velocity,
    angularVelocity: owner.angularVelocity,
    damping: 1 - owner.friction,
    density: owner.density,
    active: _isActive,
    owner: owner,
  );

  double get _spinParity => _ballVel.x.abs() > _ballVel.y.abs()
      ? _gravitySign.y * _ballVel.x.sign
      : -_gravitySign.x * _ballVel.y.sign;

  late final bool _freeRotation = true;

  /// Returns the current speed of the physical ball.
  double get speed => !_ball.isMounted ? 0 : _ballVel.length;

  late final double _invInitialRadius = 1 / (owner.size.x / 2);

  bool _isActive = true;

  /// Updates the physical radius of the connected ball.
  void setBallRadius(double x) {
    if (isMounted && _ball.isMounted) {
      _ball.radius = x;
    }
  }

  late final Vector2 _gravitySign = world.gravitySign;

  Vector2 get _ballPos =>
      kPhysicsScaleLockedAtOne ? _ballPosUnscaled : _reusableVector
        ..setFrom(_ballPosUnscaled)
        ..scale(invPhysicsScale);

  // Before Forge2D 0.15, could do late final Vector2 here
  Vector2 get _ballPosUnscaled => _ball.position;

  Vector2 get _ballVel =>
      kPhysicsScaleLockedAtOne ? _ballVelUnscaled : _reusableVector
        ..setFrom(_ballVelUnscaled)
        ..scale(invPhysicsScale);

  // Before Forge2D 0.15, could do late final Vector2 here
  Vector2 get _ballVelUnscaled => _ball.body.linearVelocity;

  void _initaliseFromOwner() {
    assert(_ball.isLoaded);
    _ball.radius = owner.radius;
    _ball.position = owner.position;
    _ball.velocity = owner.velocity;
    _ball.body.angularVelocity = owner.angularVelocity;
  }

  /// Resynchronizes the physical ball's state with the owner's current state and activates it.
  void initialiseFromOwnerAndSetDynamic() {
    assert(_ball.isLoaded);
    _ball.setActive();
    _isActive = true;
    // ball must be active before can initialise
    _initaliseFromOwner();
  }

  /// One frame of physics synchronization, updating the owner's visual properties from the ball's simulation.
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
      owner.angle += speed * dt * _invInitialRadius * _spinParity;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (owner.state != PhysicsState.full) {
      if (_isActive) {
        logGlobal("physics deactivated on update");
        deactivate();
      }
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

  @override
  void removalActions() {
    deactivate();
    _ball.removeFromParent();
    //world.destroyBody(_ball.body); //FIXME investigate
    super.removalActions();
  }

  /// Deactivates the physical ball and stops physics synchronization.
  void deactivate() {
    // disable _isActive before _ball first reference
    // as _ball is initialised by referencing _ball as late final
    _isActive = false;
    _ball.setInactive();
  }
}
