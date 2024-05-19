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
  int _ghostDeadTimeLatest = 0; //a long time ago
  int ghostSpriteChooserNumber = 100;

  Future<Map<CharacterState, SpriteAnimation>?> getAnimations() async {
    return {
      CharacterState.normal: SpriteAnimation.spriteList(
        [
          await game.loadSprite(ghostSpriteChooserNumber == 0
              ? 'dash/ghost1.png'
              : ghostSpriteChooserNumber == 1
                  ? 'dash/ghost3.png'
                  : ghostSpriteChooserNumber == 2
                      ? 'dash/ghost2.png'
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

  void setScared() {
    current = CharacterState.scared;
    ghostScaredTimeLatest = world.now;
  }

  void setDead() {
    current = CharacterState.deadGhost;
    add(ReturnHomeEffect(kGhostStartLocation));
    _ghostDeadTimeLatest = world.now;
    if (multipleSpawningGhosts) {
      world.remove(this);
    } else {
      //Move ball way offscreen. Stops any physics interactions or collisions
      setUnderlyingBallPosition(kOffScreenLocation +
          Vector2.random() /
              100); //will get moved to right position later by other code in sequence checker
      //ghost.setUnderlyingBallStatic();
    }
  }

  void setStartPositionAfterPacmanDeath() {
    setPosition(kGhostStartLocation + Vector2.random() / 100);
    _ghostDeadTimeLatest = 0;
    ghostScaredTimeLatest = 0;
  }

  void setPositionForGameEnd() {
    setPosition(kCageLocation + Vector2.random() / 100);
    _ghostDeadTimeLatest = 0;
    ghostScaredTimeLatest = 0;
  }

  void ghostDeadScaredScaredIshNormalSequence() {
    if (current == CharacterState.deadGhost) {
      if (world.now - _ghostDeadTimeLatest > kGhostResetTimeMillis) {
        if (!world.gameWonOrLost() &&
            _ghostDeadTimeLatest != 0) { //dont set on game over or after pacman death
          setPosition(kGhostStartLocation + Vector2.random() / 100);
          //setUnderlyingBallDynamic();
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
    ghostScaredTimeLatest = 0;
    world.ghostPlayersList.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    ghostDeadScaredScaredIshNormalSequence();

    if (world.physicsOn) {
      if (current == CharacterState.deadGhost) {
        /// handled by [ReturnHomeEffect]
      } else {
        oneFrameOfPhysics();
      }
    }
    super.update(dt);
  }
}
