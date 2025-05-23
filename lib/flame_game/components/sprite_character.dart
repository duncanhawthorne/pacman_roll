import 'dart:core';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../style/palette.dart';
import '../effects/remove_effects.dart';
import '../icons/stub_sprites.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'clones.dart';
import 'game_character.dart';
import 'lap_angle.dart';
import 'pacman.dart';
import 'removal_actions.dart';

final Paint _highQualityPaint =
    Paint()
      ..filterQuality = FilterQuality.high
      //..color = const Color.fromARGB(255, 255, 255, 255)
      ..isAntiAlias = true;

class SpriteCharacter extends SpriteAnimationGroupComponent<CharacterState>
    with
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame>,
        RemovalActions,
        LapAngle,
        IgnoreEvents {
  SpriteCharacter({super.position, this.original})
    : super(anchor: Anchor.center, paint: _highQualityPaint);

  late final GameCharacter? original;

  String defaultSpritePath = "";

  bool get stateTypical =>
      current != CharacterState.dead && current != CharacterState.spawning;

  late final CollisionType defaultCollisionType =
      enableRotationRaceMode
          ? CollisionType.inactive
          : this is Pacman || this is PacmanClone
          ? CollisionType.active
          : CollisionType.passive;

  late final bool isClone = this is PacmanClone || this is GhostClone;

  late final CircleHitbox hitBox = CircleHitbox(
    isSolid: true,
    collisionType: defaultCollisionType,
    radius: playerSize,
    position: Vector2.all(playerSize),
    anchor: Anchor.center,
  )..debugMode = kDebugMode && true;

  Future<Map<CharacterState, SpriteAnimation>> getSingleSprite([
    int size = 1,
  ]) async {
    return <CharacterState, SpriteAnimation>{
      CharacterState.normal: SpriteAnimation.spriteList(<Sprite>[
        await game.loadSprite(defaultSpritePath),
      ], stepTime: double.infinity),
    };
  }

  Future<Map<CharacterState, SpriteAnimation>> getAnimations([
    int size = 1,
  ]) async {
    return <CharacterState, SpriteAnimation>{};
  }

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

  @mustCallSuper
  void setPhysicsState(PhysicsState targetState) {
    assert(!isClone); //not called on clones
    if (targetState == PhysicsState.full) {
      hitBox.collisionType = defaultCollisionType;
      hitBox.debugColor = Palette.pacman.color;
    } else if (targetState == PhysicsState.partial) {
      hitBox.collisionType = CollisionType.inactive;
      hitBox.debugColor = Palette.warning.color;
    } else {
      hitBox.collisionType = CollisionType.inactive;
      hitBox.debugColor = Palette.seed.color;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _loadStubAnimationsOnDebugMode();
    add(hitBox);
  }

  @override
  void removalActions() {
    hitBox.collisionType = CollisionType.inactive;
    if (!isClone) {
      removeEffects(this); //sync and async
    }
    super.removalActions();
  }
}

enum CharacterState { normal, scared, scaredIsh, eating, dead, spawning }
