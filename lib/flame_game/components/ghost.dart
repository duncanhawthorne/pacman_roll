import 'dart:core';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../../audio/sounds.dart';
import '../constants.dart';
// ignore: unused_import
import '../helper.dart';
import 'game_character.dart';
import 'maze.dart';

const int kGhostChaseTimeMillis = 6000;
const int kGhostResetTimeMillis = 1000;

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

  //int ghostScaredTimeLatest = 0; //a long time ago
  int _ghostDeadTimeLatest = 0; //a long time ago
  int ghostSpriteChooserNumber = 100;

  Future<Map<CharacterState, SpriteAnimation>?> _getAnimations() async {
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
    if (!world.gameWonOrLost) {
      if (current != CharacterState.deadGhost) {
        // if dead, need to continue dead animation without physics applying, then get sequenced to scared via standard sequence code
        current = CharacterState.scared;
      }
      world.allGhostScaredTimeLatest = world.now;
    }
  }

  void setDead() {
    if (!world.gameWonOrLost) {
      current = CharacterState.deadGhost;
      add(ReturnHomeEffect(maze.ghostStart));
      _ghostDeadTimeLatest = world.now;
      if (multipleSpawningGhosts) {
        world.remove(this);
      } else {
        //Move ball way offscreen. Stops any physics interactions or collisions
        //Further physics doesn't apply in deadGhost state
        setUnderlyingBallPosition(maze.offScreen +
            Vector2.random() /
                100); //will get moved to right position later by other code in sequence checker
        //setUnderlyingBallStatic();
      }
    }
  }

  void setStartPositionAfterPacmanDeath() {
    setPosition(maze.ghostStart + Vector2.random() / 100);
    _ghostDeadTimeLatest = 0;
    world.allGhostScaredTimeLatest = 0;
  }

  void setPositionForGameEnd() {
    setPosition(maze.cage + Vector2.random() / 100);
    _ghostDeadTimeLatest = 0;
    world.allGhostScaredTimeLatest = 0;
  }

  void _ghostDeadScaredScaredIshNormalSequence() {
    if (current == CharacterState.deadGhost) {
      if (world.now - _ghostDeadTimeLatest > kGhostResetTimeMillis) {
        if (!world.gameWonOrLost && _ghostDeadTimeLatest != 0) {
          //dont set on game over or after pacman death
          setPosition(maze.ghostStart + Vector2.random() / 100);
          //setUnderlyingBallDynamic();
        }
        current = CharacterState.scared;
      }
    }
    if (current == CharacterState.scared) {
      if (world.now - world.allGhostScaredTimeLatest >
          kGhostChaseTimeMillis * 2 / 3) {
        current = CharacterState.scaredIsh;
      }
    }

    if (current == CharacterState.scaredIsh) {
      if (world.now - world.allGhostScaredTimeLatest > kGhostChaseTimeMillis) {
        current = CharacterState.normal;
        game.audioController.stopSfx(SfxType.ghostsScared);
      }
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    world.ghostPlayersList.add(this);
    animations = await _getAnimations();
    current = CharacterState.scared;
  }

  @override
  Future<void> onRemove() async {
    //XghostScaredTimeLatest = 0;
    world.ghostPlayersList.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    _ghostDeadScaredScaredIshNormalSequence();

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
