import 'dart:async';
import 'dart:core';

import 'package:flame/components.dart';

import '../effects/move_to_effect.dart';
import '../effects/remove_effects.dart';
import '../effects/rotate_effect.dart';
import '../maze.dart';
import 'clones.dart';
import 'game_character.dart';

const Map<int, String> _ghostSpritePaths = <int, String>{
  0: 'ghost1.png',
  1: 'ghost3.png',
  2: 'ghost2.png'
};

class Ghost extends GameCharacter {
  Ghost({required this.ghostID, super.original})
      : super(position: maze.ghostSpawnForId(ghostID));

  int ghostID;

  @override
  Future<Map<CharacterState, SpriteAnimation>?> getAnimations(
      [int size = 1]) async {
    return <CharacterState, SpriteAnimation>{
      CharacterState.normal: SpriteAnimation.spriteList(
        <Sprite>[
          await game.loadSprite(game.level.numStartingGhosts == 1
              ? _ghostSpritePaths[0]!
              : _ghostSpritePaths[ghostID % 3]!)
        ],
        stepTime: double.infinity,
      ),
      CharacterState.scared: SpriteAnimation.spriteList(
        <Sprite>[await game.loadSprite('ghostscared1.png')],
        stepTime: double.infinity,
      ),
      CharacterState.scaredIsh: SpriteAnimation.spriteList(
        <Sprite>[
          await game.loadSprite('ghostscared1.png'),
          await game.loadSprite('ghostscared2.png')
        ],
        stepTime: 0.1,
      ),
      CharacterState.dead: SpriteAnimation.spriteList(
        <Sprite>[await game.loadSprite('eyes.png')],
        stepTime: double.infinity,
      ),
      CharacterState.spawning: SpriteAnimation.spriteList(
        <Sprite>[await game.loadSprite('eyes.png')],
        stepTime: double.infinity,
      ),
    };
  }

  void setScared() {
    if (!game.isWonOrLost) {
      if (current != CharacterState.dead &&
          current != CharacterState.spawning) {
        // if dead, need to continue dead animation without physics applying,
        // then get sequenced to scared via standard sequence code
        current = CharacterState.scared;
      }
    }
  }

  void setScaredToScaredIsh() {
    if (!game.isWonOrLost) {
      if (current == CharacterState.scared) {
        current = CharacterState.scaredIsh;
      }
    }
  }

  void setScaredIshToNormal() {
    if (!game.isWonOrLost) {
      if (current == CharacterState.scaredIsh) {
        current = CharacterState.normal;
      }
    }
  }

  void setDead() {
    if (!game.isWonOrLost) {
      current = CharacterState.dead; //stops further interactions
      if (game.level.multipleSpawningGhosts) {
        removeFromParent();
      } else {
        disconnectFromBall();
        add(MoveToPositionEffect(maze.ghostStart,
            onComplete: () =>
                <void>{bringBallToSprite(), current = world.ghosts.current}));
        resetSlideAngle(this);
      }
    }
  }

  void _setSpawning() {
    if (!game.isWonOrLost) {
      current = CharacterState.spawning; //stops further interactions
      disconnectFromBall(spawning: true);
      add(MoveToPositionEffect(
          game.level.homingGhosts
              ? world.pacmans.ghostHomingTarget
              : maze.ghostStart,
          onComplete: () =>
              <void>{bringBallToSprite(), current = world.ghosts.current}));
    }
  }

  void resetSlideAfterPacmanDeath() {
    current = CharacterState.normal;
    removeEffects(this);
    disconnectFromBall();
    add(MoveToPositionEffect(maze.ghostStartForId(ghostID),
        onComplete: () => <void>{
              //bringBallToSprite()
              //Calling bringBallToSprite here creates a crash
              //also would be a race condition
            }));
    resetSlideAngle(this);
  }

  void resetInstantAfterPacmanDeath() {
    removeEffects(this);
    current = CharacterState.normal;
    setPositionStill(maze.ghostStartForId(ghostID));
    angle = 0;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (!isClone) {
      world.ghosts.ghostList.add(this);
      current = world.ghosts.current;
      if (ghostID >= 3) {
        _setSpawning();
      }
      clone = GhostClone(ghostID: ghostID, original: this);
    }
    animations = await getAnimations(); //load for clone too
  }

  @override
  Future<void> onRemove() async {
    if (!isClone) {
      world.ghosts.ghostList.remove(this);
    }
    unawaited(super.onRemove());
  }
}
