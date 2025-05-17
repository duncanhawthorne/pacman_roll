import 'dart:core';

import 'package:flame/components.dart';

import '../../utils/constants.dart';
import '../effects/remove_effects.dart';
import '../effects/rotate_effect.dart';
import '../maze.dart';
import 'clones.dart';
import 'follow_physics.dart';
import 'follow_simple_physics.dart';
import 'ghost.dart';
import 'pacman.dart';
import 'sprite_character.dart';

final Vector2 north = Vector2(0, 1);

class GameCharacter extends SpriteCharacter {
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

  final double density;

  bool possiblePhysicsConnection = true;

  bool connectedToBall =
      true; //can't rename to be private variable as overridden in clone

  final bool canAccelerate = false;

  set velocity(Vector2 v) => _velocity.setFrom(v);

  Vector2 get velocity => _velocity;
  final Vector2 _velocity = Vector2(0, 0);

  set acceleration(Vector2 v) => _acceleration.setFrom(v);

  Vector2 get acceleration => _acceleration;
  final Vector2 _acceleration = Vector2(0, 0);

  double angularVelocity = 0;

  double friction = 1;
  static Vector2 reusableVector = Vector2.zero();

  bool get typical => connectedToBall && stateTypical;

  bool _cloneEverMade = false; //could just test clone is null
  GameCharacter? _clone;

  double get radius => size.x.toDouble() / 2;

  set radius(double x) => _setRadius(x);

  double get speed => _physics.speed;

  void _setRadius(double x) {
    size = Vector2.all(x * 2);
    _physics.setBallRadius(x);
  }

  late final Physics _physics = Physics(owner: this);
  late final SimplePhysics _simplePhysics = SimplePhysics(owner: this);

  void disconnectFromBall({bool spawning = false}) {
    if (!spawning) {
      //FIXME deal with spawning
      setImpreciseMode();
    }
  }

  void bringBallToSprite() {
    if (isMounted && !isRemoving) {
      //FIXME check if still need this test
      // must test isMounted as bringBallToSprite typically runs after a delay
      // and could have reset to remove the ball in the meantime
      setPositionStill(position);
    }
  }

  @override
  void setPreciseMode() {
    super.setPreciseMode();
    _initialisePhysics();
  }

  @override
  void setImpreciseMode() {
    super.setImpreciseMode();
    _initialiseSimplePhysics();
  }

  void _initialisePhysics() {
    _physics.initaliseFromOwner();
    connectedToBall = true;
    if (children.contains(_simplePhysics)) {
      _simplePhysics.removeFromParent();
    }
    if (!children.contains(_physics)) {
      add(_physics);
    }
  }

  void _initialiseSimplePhysics() {
    if (children.contains(_physics)) {
      _physics.removeFromParent();
    }
    if (!children.contains(_simplePhysics)) {
      add(_simplePhysics);
    }
    connectedToBall = false;
  }

  void _disconnectFromBall() {
    _physics.removeFromParent();
    assert(!isClone); //as for clone have no way to turn collisionType back on
    connectedToBall = false;
  }

  void setPositionStill(Vector2 targetLoc) {
    position.setFrom(targetLoc);
    velocity.setAll(0);
    acceleration.setAll(0);
    angularVelocity = 0;
    _physics.initaliseFromOwner();
    setPreciseMode();
  }

  void setPositionStillInactive(Vector2 targetLoc) {
    position.setFrom(targetLoc);
    velocity.setAll(0);
    acceleration.setAll(0);
    angularVelocity = 0;
    _physics.initaliseFromOwner();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (!isClone) {
      setPreciseMode();
    }
    if (enableRotationRaceMode) {
      _lapAngleLast = _getLapAngle();
    }
  }

  @override
  void removalActions() {
    super.removalActions();
    if (!isClone) {
      _physics.ownerRemovedActions();
      _disconnectFromBall(); //sync but within async function
      _cloneEverMade ? _clone?.removeFromParent() : null;
      removeEffects(this); //sync and async
    }
  }

  @override
  void removeFromParent() {
    removalActions();
    super.removeFromParent(); //async
  }

  @override
  Future<void> onRemove() async {
    removalActions();
    await super.onRemove();
  }

  void _addRemoveClone() {
    if (isClone) {
      return;
    }
    assert(!isClone); //i.e. no cascade of clones
    if (position.x.abs() > maze.cloneThreshold) {
      if (!_cloneEverMade) {
        assert(_clone == null);
        _cloneEverMade = true;
        if (this is Pacman) {
          _clone = PacmanClone(position: position, original: this as Pacman);
        } else if (this is Ghost) {
          _clone = GhostClone(
            ghostID: (this as Ghost).ghostID,
            original: this as Ghost,
          );
        }
      }
      assert(_clone != null);
      assert(_clone!.isClone);
      assert(!isClone);
      if (!_clone!.isMounted) {
        parent?.add(_clone!);
      }
    } else {
      if (_cloneEverMade && _clone!.isMounted) {
        assert(_clone != null);
        _clone?.removeFromParent();
      }
    }
  }

  late double _lapAngleLast;
  double lapAngleProgress = 0;

  double _getLapAngle() {
    return position.screenAngle();
  }

  void _updateLapAngle() {
    if (!enableRotationRaceMode) {
      return;
    }
    lapAngleProgress += smallAngle(_getLapAngle() - _lapAngleLast);
    _lapAngleLast = _getLapAngle();
  }

  @override
  void update(double dt) {
    //note, this function is also run for clones
    _addRemoveClone();
    _updateLapAngle();
    super.update(dt);
  }
}
