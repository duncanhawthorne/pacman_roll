import 'dart:core';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../effects/remove_effects.dart';
import '../icons/stub_sprites.dart';
import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'clones.dart';
import 'pacman.dart';
import 'physics_ball.dart';

final Paint _highQualityPaint = Paint()
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
            anchor: Anchor.center);

  late final PhysicsBall _ball = PhysicsBall(position: position);

  bool connectedToBall = true;

  double get speed => _ball.speed;

  double get _spinParity =>
      _ball.body.linearVelocity.x.abs() > _ball.body.linearVelocity.y.abs()
          ? world.gravityYSign * _ball.body.linearVelocity.x.sign
          : -world.gravityXSign * _ball.body.linearVelocity.y.sign;

  bool get typical =>
      connectedToBall &&
      current != CharacterState.dead &&
      current != CharacterState.spawning;

  CollisionType get _collisionType => this is Pacman || this is PacmanClone
      ? CollisionType.active
      : CollisionType.passive;

  late final bool isClone = this is PacmanClone || this is GhostClone;

  late final GameCharacter? clone;
  late final GameCharacter? original;
  late final CircleHitbox hitbox =
      CircleHitbox(isSolid: true, collisionType: _collisionType);

  late final double radius = size.x / 2;

  void loadStubAnimationsOnDebugMode() {
    // works around changes made in flame 1.19
    // where animations have to be loaded before can set current
    // only fails due to assert, which is only tested in debug mode
    // so if in debug mode, quickly load up stub animations first
    // https://github.com/flame-engine/flame/pull/3258
    if (kDebugMode) {
      animations = stubSprites.stubAnimation;
    }
  }

  Future<Map<CharacterState, SpriteAnimation>?> getAnimations(
      [int size = 1]) async {
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
    hitbox.collisionType = CollisionType.inactive;
  }

  void _connectToBall() {
    connectedToBall = true;
    _ball.setDynamic();
    assert(!isClone); //not called on clones
    hitbox.collisionType = _collisionType;
  }

  void _oneFrameOfPhysics(double dt) {
    if (connectedToBall) {
      position.setFrom(_ball.position);
      angle += speed * dt / radius * _spinParity;
    }
  }

  @override
  void removeFromParent() {
    if (!isClone) {
      disconnectFromBall(); //sync
      removeEffects(this); //sync and async
    }
    super.removeFromParent(); //async
  }

  @override
  Future<void> onLoad() async {
    loadStubAnimationsOnDebugMode();
    if (!isClone) {
      parent!
          .add(_ball); //should be added to static parent but risks going stray
    }
    add(hitbox);
  }

  @override
  Future<void> onRemove() async {
    if (!isClone) {
      //removeEffects(this); //dont run this, runs async code which will execute after the item has already been removed and cause a crash
      disconnectFromBall(); //sync but within async function
      _ball.removeFromParent();
      clone?.removeFromParent();
    }
    super.onRemove();
  }

  void _addRemoveClone() {
    if (!isClone) {
      //i.e. no cascade of clones
      assert(clone != null);
      assert(clone!.isClone);
      assert(!isClone);
      if (position.x.abs() > maze.cloneThreshold) {
        if (!clone!.isMounted) {
          parent!.add(clone!);
        }
      } else {
        if (clone!.isMounted) {
          clone!.removeFromParent();
        }
      }
    }
  }

  @override
  void update(double dt) {
    //note, this function is also run for clones
    _oneFrameOfPhysics(dt);
    _addRemoveClone();
    super.update(dt);
  }
}

enum CharacterState { normal, scared, scaredIsh, eating, dead, spawning }
