import 'dart:core';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../utils/helper.dart';
import '../effects/move_to_effect.dart';
import '../effects/rotate_by_effect.dart';
import '../maze.dart';
import 'clones.dart';
import 'game_character.dart';

final _ghostSpriteMap = {0: 'ghost1.png', 1: 'ghost3.png', 2: 'ghost2.png'};

class Ghost extends GameCharacter {
  Ghost({required this.idNum, super.original})
      : super(position: maze.ghostSpawnForId(idNum));

  int idNum;

  Future<Map<CharacterState, SpriteAnimation>?> _getAnimations() async {
    return {
      CharacterState.normal: SpriteAnimation.spriteList(
        [await game.loadSprite(_ghostSpriteMap[idNum % 3]!)],
        stepTime: double.infinity,
      ),
      CharacterState.scared: SpriteAnimation.spriteList(
        [await game.loadSprite('ghostscared1.png')],
        stepTime: double.infinity,
      ),
      CharacterState.scaredIsh: SpriteAnimation.spriteList(
        [
          await game.loadSprite('ghostscared1.png'),
          await game.loadSprite('ghostscared2.png')
        ],
        stepTime: 0.1,
      ),
      CharacterState.dead: SpriteAnimation.spriteList(
        [await game.loadSprite('eyes.png')],
        stepTime: double.infinity,
      ),
      CharacterState.spawning: SpriteAnimation.spriteList(
        [await game.loadSprite('eyes.png')],
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

  void setScaredToScaredIsh() {
    if (!world.gameWonOrLost) {
      if (current == CharacterState.scared) {
        current = CharacterState.scaredIsh;
      }
    }
  }

  void setScaredIshToNormal() {
    if (!world.gameWonOrLost) {
      if (current == CharacterState.scaredIsh) {
        current = CharacterState.normal;
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
                {bringBallToSprite(), current = world.ghosts.current}));
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
              {bringBallToSprite(), current = world.ghosts.current}));
    }
  }

  void resetSlideAfterPacmanDeath() {
    current = CharacterState.normal;
    removeWhere((item) => item is Effect);
    disconnectFromBall();
    add(MoveToPositionEffect(maze.ghostStartForId(idNum),
        onComplete: () => {
              //bringBallToSprite()
              //Calling bringBallToSprite here creates a crash
              //also would be a race condition
            }));
    add(RotateByAngleEffect(smallAngle(-angle)));
  }

  void resetInstantAfterPacmanDeath() {
    removeWhere((item) => item is Effect);
    current = CharacterState.normal;
    setPositionStill(maze.ghostStartForId(idNum));
    angle = 0;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    world.ghosts.ghostList.add(this);
    current = world.ghosts.current;
    if (idNum >= 3) {
      _setSpawning();
    }
    if (portalClones) {
      clone = GhostClone(position: position, idNum: idNum, original: this);
    }
    animations = await _getAnimations();
  }

  @override
  Future<void> onGameResize(Vector2 size) async {
    //load animations here too, for clone, which doesn't run onLoad
    //can't just run it here, as runs slower than onLoad, so causes a flash here
    animations ??= await _getAnimations();
    super.onGameResize(size);
  }

  @override
  Future<void> onRemove() async {
    world.ghosts.ghostList.remove(this);
    super.onRemove();
  }
}
