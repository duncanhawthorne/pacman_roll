import 'package:flame/components.dart';

import '../effects/remove_effects.dart';
import 'clone_manager.dart';
import 'follow_physics.dart';
import 'follow_simple_physics.dart';
import 'sprite_character.dart';

/// Base class for interactive characters with physics and animations.
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
  final Vector2 _velocity = Vector2.zero();

  final bool canAccelerate = false;

  Vector2 get acceleration => _acceleration;

  set acceleration(Vector2 v) => _acceleration.setFrom(v);
  final Vector2 _acceleration = Vector2.zero();

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

  /// Determines if the character is in a typical state (active and not dying/spawning).
  bool get typical => state == PhysicsState.full && stateTypical;

  late final Physics _physics = Physics(owner: this);
  late final SimplePhysics _simplePhysics = SimplePhysics(owner: this);

  /// Current state of the character's physics (Full, Partial, or None).
  PhysicsState state = PhysicsState.unset;

  @override
  /// Transitions the character between different physics simulation modes.
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
          _physics.initializeFromOwnerAndSetDynamic();
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

  /// Resets the character's position and sets it to an active physics state.
  void setPositionStillActive(Vector2 targetLoc) {
    _setStill(targetLoc);
    setPhysicsState(PhysicsState.full);
  }

  /// Resets the character's position and disables its physics.
  void setPositionStillStatic(Vector2 targetLoc) {
    setPhysicsState(PhysicsState.none);
    _setStill(targetLoc);
  }

  /// Helper to stop all character movement and set a new position.
  void _setStill(Vector2 targetLoc) {
    position.setFrom(targetLoc);
    velocity.setAll(0);
    acceleration.setAll(0);
    angularVelocity = 0;
  }

  void forceReinitializePhysics() {
    if (!isLoaded) {
      return; // no action required as loading will initialize
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
