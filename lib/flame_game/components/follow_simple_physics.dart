import 'package:flame/components.dart';

import '../custom_world.dart';
import 'game_character.dart';

/// A component that handles basic kinematics for characters when full physics is disabled.
class SimplePhysics extends Component with HasWorldReference<CustomWorld> {
  SimplePhysics({required this.owner});

  late final GameCharacter owner;

  /// Applies basic kinematic equations (velocity, acceleration, friction) to the character.
  void _oneFrameOfSimpleMovement(double dt) {
    if (owner.canAccelerate) {
      owner.velocity.addScaled(owner.acceleration, dt);
    }
    if (owner.friction != 1) {
      owner.velocity.scale(owner.friction);
    }
    owner.position.addScaled(owner.velocity, dt);
    owner.angle += owner.angularVelocity * dt;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (owner.state != PhysicsState.partial) {
      return;
    }
    _oneFrameOfSimpleMovement(dt);
  }
}
