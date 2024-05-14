import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../constants.dart';
// ignore: unused_import
import '../helper.dart';
import 'game_character.dart';
import 'dart:core';

import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

/// The [JumpEffect] is simply a [MoveByEffect] which has the properties of the
/// effect pre-defined.
class ReturnHomeEffect extends MoveToEffect {
  ReturnHomeEffect(Vector2 destination)
      : super(
            destination,
            EffectController(
                duration: kGhostResetTimeMillis / 1000, curve: Curves.linear));
}

class Ghost extends GameCharacter {
  Ghost({
    required super.position,
  }) : super();

  int ghostScaredTimeLatest = 0; //a long time ago
  int ghostDeadTimeLatest = 0; //a long time ago
  int ghostSpriteChooserNumber = 100;

  Future<Map<CharacterState, SpriteAnimation>?> getAnimations() async {
    return {
      CharacterState.normal: SpriteAnimation.spriteList(
        [
          await game.loadSprite(ghostSpriteChooserNumber == 0
              ? 'dash/ghost1.png'
              : ghostSpriteChooserNumber == 1
                  ? 'dash/ghost2.png'
                  : ghostSpriteChooserNumber == 2
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
        stepTime: double.infinity,
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
        if (world.pelletsRemainingNotifier.value > 0 &&
            ghostDeadTimeLatest != 0) {
          setPosition(
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
        game.audioController.stopSfx(SfxType.ghostsScared);
      }
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    world.ghostPlayersList.add(this);
    animations = await getAnimations();
    current = CharacterState.scared;
  }

  @override
  Future<void> onRemove() async {
    world.ghostPlayersList.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    ghostDeadScaredScaredIshNormalSequence();

    if (globalPhysicsLinked) {
      if (current == CharacterState.deadGhost) {
        /// handled by [ReturnHomeEffect]
      } else {
        oneFrameOfPhysics();
      }
    }
    super.update(dt);
  }
}
