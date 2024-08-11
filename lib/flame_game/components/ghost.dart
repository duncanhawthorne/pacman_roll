import 'dart:core';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../audio/sounds.dart';
import '../../utils/helper.dart';
import '../effects/move_to_effect.dart';
import '../effects/rotate_by_effect.dart';
import '../maze.dart';
import 'game_character.dart';

const int _kGhostChaseTimeMillis = 6000;
const int kGhostResetTimeMillis = 1000;

final _ghostSpriteMap = {
  0: 'dash/ghost1.png',
  1: 'dash/ghost3.png',
  2: 'dash/ghost2.png'
};

class Ghost extends GameCharacter {
  Ghost({
    required this.idNum,
  }) : super(position: maze.ghostSpawnForId(idNum));

  int idNum;

  Future<Map<CharacterState, SpriteAnimation>?> _getAnimations() async {
    return {
      CharacterState.normal: SpriteAnimation.spriteList(
        [await game.loadSprite(_ghostSpriteMap[idNum % 3]!)],
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
      CharacterState.dead: SpriteAnimation.spriteList(
        [await game.loadSprite('dash/eyes.png')],
        stepTime: double.infinity,
      ),
      CharacterState.spawning: SpriteAnimation.spriteList(
        [await game.loadSprite('dash/eyes.png')],
        stepTime: double.infinity,
      ),
    };
  }

  void setScared() {
    if (!world.gameWonOrLost) {
      if (current != CharacterState.dead &&
          current != CharacterState.spawning) {
        // if dead, need to continue dead animation without physics applying, then get sequenced to scared via standard sequence code
        current = CharacterState.scared;
      }
    }
  }

  void setDead() {
    if (!world.gameWonOrLost) {
      current = CharacterState.dead; //stops further interactions
      if (game.level.multipleSpawningGhosts) {
        disconnectFromBall(); //sync
        removeFromParent(); //async
      } else {
        disconnectFromBall();
        add(MoveToPositionEffect(maze.ghostStart,
            onComplete: () =>
                {bringBallToSprite(), current = CharacterState.scared}));
        add(RotateByAngleEffect(smallAngle(-angle)));
      }
    }
  }

  void _setSpawning() {
    if (!world.gameWonOrLost) {
      current = CharacterState.spawning; //stops further interactions
      disconnectFromBall(spawning: true);
      add(MoveToPositionEffect(
          world.level.homingGhosts
              ? (Vector2.all(0)..setFrom(world.pacmans.pacmanList[0].position))
              : maze.ghostStart,
          onComplete: () =>
              {bringBallToSprite(), current = CharacterState.scared}));
    }
  }

  void resetSlideAfterPacmanDeath() {
    current = CharacterState.normal;
    removeWhere((item) => item is Effect);
    disconnectFromBall();
    //add(MoveToPositionEffect(maze.ghostStartForId(idNum)));
    //add(MoveToPositionEffect(maze.ghostStartForId(idNum),
    //    onComplete: bringBallToSprite));
    add(MoveToPositionEffect(maze.ghostStartForId(idNum),
        onComplete: () => {
              //bringBallToSprite()
            })); //FIXME should be able to call bringBallToSprite here
    add(RotateByAngleEffect(smallAngle(-angle)));
  }

  void resetInstantAfterPacmanDeath() {
    removeWhere((item) => item is Effect);
    current = CharacterState.normal;
    setPositionStill(maze.ghostStartForId(idNum));
    angle = 0;
  }

  void _stateSequence() {
    if (current == CharacterState.scared) {
      if (game.now - world.ghosts.scaredTimeLatest >
          _kGhostChaseTimeMillis * 2 / 3) {
        current = CharacterState.scaredIsh;
      }
    }
    if (current == CharacterState.scaredIsh) {
      if (game.now - world.ghosts.scaredTimeLatest > _kGhostChaseTimeMillis) {
        current = CharacterState.normal;
        game.audioController.stopSfx(SfxType.ghostsScared);
      }
    }
  }

  @override
  Future<void> onLoad() async {
    world.ghosts.ghostList.add(this);
    animations = await _getAnimations();
    current = CharacterState.scared;
    if (idNum >= 3) {
      _setSpawning();
    }
    super.onLoad();
  }

  @override
  Future<void> onRemove() async {
    world.ghosts.ghostList.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    _stateSequence();
    super.update(dt);
  }
}
