import 'dart:core';

import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../../utils/helper.dart';
import '../effects/return_home_effect.dart';
import 'game_character.dart';
import 'maze.dart';

const int kGhostChaseTimeMillis = 6000;
const int kGhostResetTimeMillis = 1000;
const multipleSpawningGhosts = false;

class Ghost extends GameCharacter {
  Ghost({
    required super.position,
  }) : super();

  //int ghostScaredTimeLatest = 0; //a long time ago
  int _ghostDeadTimeLatest = 0; //a long time ago
  int idNum = 100;

  Future<Map<CharacterState, SpriteAnimation>?> _getAnimations() async {
    return {
      CharacterState.normal: SpriteAnimation.spriteList(
        [
          await game.loadSprite(idNum == 0
              ? 'dash/ghost1.png'
              : idNum == 1
                  ? 'dash/ghost3.png'
                  : idNum == 2
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
      current = CharacterState.deadGhost; //stops further interactions
      _ghostDeadTimeLatest = world.now;
      if (multipleSpawningGhosts) {
        world.remove(this);
      } else {
        disconnectSpriteFromBall();
        add(ReturnHomeEffect(maze.ghostStart));
        add(RotateHomeEffect(smallAngle(-angle)));
        //will get moved to right position later by code in sequence checker
      }
    }
  }

  void setStartPositionAfterPacmanDeath() {
    setPositionStill(maze.ghostStartForId(idNum));
    angle = 0;
    _ghostDeadTimeLatest = 0;
    world.allGhostScaredTimeLatest = 0;
  }

  void slideToStartPositionAfterPacmanDeath() {
    disconnectSpriteFromBall();
    add(ReturnHomeEffect(maze.ghostStartForId(idNum)));
    add(RotateHomeEffect(smallAngle(-angle)));
    disconnectFromPhysics();
  }

  void setPositionForGameEnd() {
    setPositionStill(maze.cage + Vector2.random() / 100);
    _ghostDeadTimeLatest = 0;
    world.allGhostScaredTimeLatest = 0;
  }

  void _ghostDeadScaredScaredIshNormalSequence() {
    if (current == CharacterState.deadGhost) {
      if (world.now - _ghostDeadTimeLatest > kGhostResetTimeMillis) {
        if (!world.gameWonOrLost && _ghostDeadTimeLatest != 0) {
          //dont set on game over or after pacman death
          setPositionStill(maze.ghostStart + Vector2.random() / 100);
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
    super.update(dt);
  }
}
