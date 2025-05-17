import 'dart:core';

import 'package:flame/components.dart';

import '../pacman_world.dart';
import 'game_character.dart';

class SimplePhysics extends Component with HasWorldReference<PacmanWorld> {
  SimplePhysics({required this.owner});

  late final GameCharacter owner;

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
    _oneFrameOfSimpleMovement(dt);
  }

  void removalActions() {
    //super.removalActions();
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
