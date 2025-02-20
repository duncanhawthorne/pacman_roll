import 'dart:core';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../utils/constants.dart';
import '../effects/remove_effects.dart';
import '../effects/rotate_effect.dart';
import '../icons/stub_sprites.dart';
import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'clones.dart';
import 'ghost.dart';
import 'pacman.dart';
import 'physics_ball.dart';

final Paint _highQualityPaint =
    Paint()
      ..filterQuality = FilterQuality.high
      //..color = const Color.fromARGB(255, 255, 255, 255)
      ..isAntiAlias = true;

final Vector2 _kVector2Zero = Vector2.zero();

/// The [GameCharacter] is the generic object that is linked to a [PhysicsBall]
class GameCharacter extends SpriteAnimationGroupComponent<CharacterState>
    with
        //CollisionCallbacks,
        IgnoreEvents,
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame> {
  GameCharacter({super.position, this.original})
    : super(
        size: maze.spriteSize,
        paint: _highQualityPaint,
        anchor: Anchor.center,
      );

  late final PhysicsBall _ball = PhysicsBall(
    position: position,
  ); //never created for clone
  late final Vector2 _ballPos = _ball.position;
  late final Vector2 _ballVel = _ball.body.linearVelocity;
  late final Vector2 _gravitySign = world.gravitySign;

  bool connectedToBall =
      true; //can't rename to be private variable as overridden in clone

  double get speed => _ballVel.length;

  double get _spinParity =>
      _ballVel.x.abs() > _ballVel.y.abs()
          ? _gravitySign.y * _ballVel.x.sign
          : -_gravitySign.x * _ballVel.y.sign;

  bool get typical =>
      connectedToBall &&
      current != CharacterState.dead &&
      current != CharacterState.spawning;

  late final CollisionType _defaultCollisionType =
      enableRotationRaceMode
          ? CollisionType.inactive
          : this is Pacman || this is PacmanClone
          ? CollisionType.active
          : CollisionType.passive;

  late final bool isClone = this is PacmanClone || this is GhostClone;

  bool _cloneEverMade = false; //could just test clone is null
  GameCharacter? _clone;
  late final GameCharacter? original;

  late final CircleHitbox _hitbox = CircleHitbox(
    isSolid: true,
    collisionType: _defaultCollisionType,
  );

  late final double _radius = size.x / 2;

  void _loadStubAnimationsOnDebugMode() {
    // works around changes made in flame 1.19
    // where animations have to be loaded before can set current
    // only fails due to assert, which is only tested in debug mode
    // so if in debug mode, quickly load up stub animations first
    // https://github.com/flame-engine/flame/pull/3258
    if (kDebugMode) {
      animations = stubSprites.stubAnimation;
    }
  }

  Future<Map<CharacterState, SpriteAnimation>> getAnimations([
    int size = 1,
  ]) async {
    return <CharacterState, SpriteAnimation>{};
  }

  void bringBallToSprite() {
    if (isMounted && !isRemoving) {
      // must test isMounted as bringBallToSprite typically runs after a delay
      // and could have reset to remove the ball in the meantime
      setPositionStill(position);
    }
  }

  void setPositionStill(Vector2 targetLoc) {
    _ball
      ..position = targetLoc
      ..velocity = _kVector2Zero;
    position.setFrom(targetLoc);
    _connectToBall();
  }

  void disconnectFromBall({bool spawning = false}) {
    assert(!isClone); //as for clone have no way to turn collisionType back on
    if (!spawning) {
      /// if body not yet initialised, this will crash
      _ball.setStatic();
    }
    connectedToBall = false;
    _hitbox.collisionType = CollisionType.inactive;
  }

  void _connectToBall() {
    connectedToBall = true;
    _ball.setDynamic();
    assert(!isClone); //not called on clones
    _hitbox.collisionType = _defaultCollisionType;
  }

  void _oneFrameOfPhysics(double dt) {
    if (connectedToBall) {
      assert(!isClone);
      position.setFrom(_ballPos);
      if (openSpaceMovement) {
        angle = _ball.angle;
      } else {
        angle += speed * dt / _radius * _spinParity;
      }
    }
  }

  @override
  Future<void> onLoad() async {
    _loadStubAnimationsOnDebugMode();
    if (!isClone) {
      parent!.add(
        _ball,
      ); //should be added to static parent but risks going stray
    }
    add(_hitbox);
    if (enableRotationRaceMode) {
      _lapAngleLast = _getLapAngle();
    }
  }

  @mustCallSuper
  void removalActions() {
    if (!isClone) {
      //removeEffects(this); //dont run this, runs async code which will execute after the item has already been removed and cause a crash
      disconnectFromBall(); //sync but within async function
      _ball.removeFromParent();
      world.destroyBody(_ball.body);
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
    super.onRemove();
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
    _oneFrameOfPhysics(dt);
    _addRemoveClone();
    _updateLapAngle();
    super.update(dt);
  }
}

enum CharacterState { normal, scared, scaredIsh, eating, dead, spawning }
