import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../style/palette.dart';
import '../../utils/constants.dart';
import '../custom_game.dart';
import '../custom_world.dart';
import '../effects/remove_effects.dart';
import '../icons/stub_sprites.dart';
import '../maze/maze.dart';
import 'clones.dart';
import 'game_character.dart';
import 'lap_angle.dart';
import 'pacman.dart';
import 'removal_actions.dart';

final Paint _highQualityPaint = Paint()
  ..filterQuality = FilterQuality.high
  //..color = const Color.fromARGB(255, 255, 255, 255)
  ..isAntiAlias = true;

/// Component that handles the visual animation and collision hitbox for game characters.
class SpriteCharacter extends SpriteAnimationGroupComponent<CharacterState>
    with
        HasWorldReference<CustomWorld>,
        HasGameReference<CustomGame>,
        RemovalActions,
        LapAngle,
        IgnoreEvents {
  SpriteCharacter({super.position, this.original})
    : super(anchor: Anchor.center, paint: _highQualityPaint);

  /// Reference to the original character if this is a visual clone.
  late final GameCharacter? original;

  String defaultSpritePath = "";

  /// Returns true if the character is in a "typical" gameplay state (e.g., not dead or spawning).
  bool get stateTypical =>
      current != CharacterState.dead && current != CharacterState.spawning;

  /// Default collision behavior based on character type and game mode.
  late final CollisionType defaultCollisionType = _getDefaultCollisionType();

  CollisionType _getDefaultCollisionType() {
    if (enableRotationRaceMode) return CollisionType.inactive;
    if (this is Pacman || this is PacmanClone) return CollisionType.active;
    return CollisionType.passive;
  }

  late final bool isClone = this is PacmanClone || this is GhostClone;

  late final CircleHitbox hitBox = CircleHitbox(
    isSolid: true,
    collisionType: defaultCollisionType,
    radius: maze.dimensions.spriteWidth / 2,
    position: Vector2.all(maze.dimensions.spriteWidth / 2),
    anchor: Anchor.center,
  )..debugMode = drawDebugBoxes;

  /// Returns a map with a single sprite animation for the current state.
  Future<Map<CharacterState, SpriteAnimation>> getSingleSprite([
    int size = 1,
  ]) async {
    return <CharacterState, SpriteAnimation>{
      CharacterState.normal: SpriteAnimation.spriteList(<Sprite>[
        await game.loadSprite(defaultSpritePath),
      ], stepTime: double.infinity),
    };
  }

  /// Asynchronously loads all sprite animations required for the character.
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

  /// Updates the collision and debug visualization based on the target physics state.
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

/// Represents the possible visual and behavioral states of a character.
enum CharacterState { normal, scared, scaredIsh, eating, dead, spawning }
