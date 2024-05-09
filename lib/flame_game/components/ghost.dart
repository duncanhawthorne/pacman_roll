import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../constants.dart';
// ignore: unused_import
import '../helper.dart';
import 'game_character.dart';
import 'dart:math';
import 'dart:core';

/// The [GameCharacter] is the component that the physical player of the game is
/// controlling.
class Ghost extends GameCharacter {
  Ghost({
    required this.startPosition,
    super.position,
  }) : super(startingPosition: startPosition);

  final Vector2 startPosition;

  int ghostScaredTimeLatest = 0; //a long time ago
  int ghostDeadTimeLatest = 0; //a long time ago
  Vector2 ghostDeadPosition = Vector2(0, 0);

  Future<Map<CharacterState, SpriteAnimation>?> getAnimations() async {
    return {
      CharacterState.normal: SpriteAnimation.spriteList(
        [
          await game.loadSprite(ghostNumberForSprite == 0
              ? 'dash/ghost1.png'
              : ghostNumberForSprite == 1
                  ? 'dash/ghost2.png'
                  : ghostNumberForSprite == 2
                      ? 'dash/ghost3.png'
                      : [
                          'dash/ghost1.png',
                          'dash/ghost2.png',
                          'dash/ghost3.png'
                        ][world.random.nextInt(3)])
        ],
        stepTime: double.infinity,
      ),
      CharacterState.scared: SpriteAnimation.spriteList(
        [await game.loadSprite('dash/ghostscared1.png')],
        stepTime: 0.1,
      ),
      CharacterState.scaredIsh: SpriteAnimation.spriteList(
        [
          await game.loadSprite('dash/ghostscared1.png'),
          await game.loadSprite('dash/ghostscared2.png')
        ],
        stepTime: 0.1,
      ),
      CharacterState.deadGhost: SpriteAnimation.spriteList(
        [await game.loadSprite('dash/eyes.png')],
        stepTime: double.infinity,
      ),
    };
  }

  void ghostDeadScaredScaredIshNormalSequence() {
    if (current == CharacterState.deadGhost) {
      if (world.now - ghostDeadTimeLatest > kGhostResetTimeMillis) {
        if (world.pelletsRemaining > 0) {
          setUnderlyingBallPosition(
              kGhostStartLocation + Vector2.random() / 100);
        }
        current = CharacterState.scared;
      }
    }
    if (current == CharacterState.scared) {
      if (world.now - ghostScaredTimeLatest > kGhostChaseTimeMillis * 2 / 3) {
        current = CharacterState.scaredIsh;
      }
    }

    if (current == CharacterState.scaredIsh) {
      if (world.now - ghostScaredTimeLatest > kGhostChaseTimeMillis) {
        current = CharacterState.normal;
        game.audioController.pauseSfx(SfxType.ghostsScared);
      }
    }
  }

  Vector2 getFlyingDeadGhostPosition() {
    double timefrac =
        (world.now - ghostDeadTimeLatest) / (kGhostResetTimeMillis);
    timefrac = min(1, timefrac);

    return world.screenPos(
        ghostDeadPosition * (1 - timefrac) + kGhostStartLocation * (timefrac));
  }

  @override
  Future<void> onLoad() async {
    animations = await getAnimations();
    setUnderlyingBallPosition(
        startingPosition); //FIXME shouldn't be necessary, but avoids one frame starting glitch
    current = CharacterState.deadGhost;

    // When adding a CircleHitbox without any arguments it automatically
    // fills up the size of the component as much as it can without overflowing
    // it.
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    ghostDeadScaredScaredIshNormalSequence();

    if (globalPhysicsLinked) {
      if (current == CharacterState.deadGhost) {
        position = getFlyingDeadGhostPosition();
      } else {
        oneFrameOfPhysics();
      }
    }
    super.update(dt);
  }
}
