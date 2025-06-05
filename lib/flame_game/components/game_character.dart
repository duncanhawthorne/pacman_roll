import 'dart:core';

import 'package:flame/components.dart';

import '../effects/remove_effects.dart';
import '../maze.dart';
import 'clone_manager.dart';
import 'follow_physics.dart';
import 'follow_simple_physics.dart';
import 'sprite_character.dart';

double get playerSize => maze.spriteWidth / 2;

class GameCharacter extends SpriteCharacter with CloneManager {
  GameCharacter({
    super.position,
    required Vector2 velocity,
    required double radius,
    this.density = 1,
    super.original,
  }) {
    this.velocity = velocity; //uses setter
    size = Vector2.all(radius * 2);
  }

  bool possiblePhysicsConnection = true;

  Vector2 get velocity => _velocity;
  set velocity(Vector2 v) => _velocity.setFrom(v);
  final Vector2 _velocity = Vector2(0, 0);

  final bool canAccelerate = false;

  Vector2 get acceleration => _acceleration;
  set acceleration(Vector2 v) => _acceleration.setFrom(v);
  final Vector2 _acceleration = Vector2(0, 0);

  double angularVelocity = 0;

  final double density;
  double friction = 1;

  double get speed => _physics.speed;

  double get radius => size.x.toDouble() / 2;
  set radius(double x) => _setRadius(x);

  void _setRadius(double x) {
    size = Vector2.all(x * 2);
    _physics.setBallRadius(x);
  }

  bool get typical => state == PhysicsState.full && stateTypical;

  late final Physics _physics = Physics(owner: this);
  late final SimplePhysics _simplePhysics = SimplePhysics(owner: this);

  PhysicsState state = PhysicsState.unset;
  @override
  void setPhysicsState(PhysicsState targetState, {bool starting = false}) {
    super.setPhysicsState(targetState);
    if (targetState == PhysicsState.full) {
      if (isRemoving) {
        return;
      }
      assert((_physics.isLoaded && isLoaded) || starting == true, this);
      if (!starting) {
        assert(_physics.isLoaded);
        if (_physics.isLoaded) {
          _physics.initaliseFromOwnerAndSetDynamic();
        }
      }
      state = PhysicsState.full;
    } else if (targetState == PhysicsState.partial) {
      state = PhysicsState.partial;
      _physics.deactivate();
    } else {
      state = PhysicsState.none;
      _physics.deactivate();
    }
  }

  void setPositionStillActiveCurrentPosition() {
    //separate function so can be called from effects
    setPositionStillActive(position);
  }

  void setPositionStillActive(Vector2 targetLoc) {
    _setStill(targetLoc);
    setPhysicsState(PhysicsState.full);
  }

  void setPositionStillStatic(Vector2 targetLoc) {
    setPhysicsState(PhysicsState.none);
    _setStill(targetLoc);
  }

  void _setStill(Vector2 targetLoc) {
    position.setFrom(targetLoc);
    velocity.setAll(0);
    acceleration.setAll(0);
    angularVelocity = 0;
  }

  void forceReinitialisePhysics() {
    if (!isLoaded) {
      return; // no action required as loading will initialise
    }
    setPhysicsState(PhysicsState.full);
  }

  @override
  Future<void> onLoad() async {
    if (!isClone) {
      add(_physics);
      add(_simplePhysics);
    }
    await super.onLoad();
  }

  @override
  void removalActions() {
    super.removalActions();
    if (!isClone) {
      setPhysicsState(PhysicsState.none);
      removeEffects(this); //sync and async
      _physics.removeFromParent();
    }
  }
}

enum PhysicsState { full, partial, none, unset }
