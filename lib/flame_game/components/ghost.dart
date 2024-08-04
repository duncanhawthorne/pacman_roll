import 'dart:core';

import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../../utils/helper.dart';
import '../effects/move_to_effect.dart';
import '../effects/rotate_by_effect.dart';
import '../maze.dart';
import 'game_character.dart';

const int kGhostChaseTimeMillis = 6000;
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

  int _ghostDeadTimeLatest = 0; //a long time ago
  int idNum;
  Vector2? _specialSpawnLocation;

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
    }
  }

  void setDead({spawningDeath = false}) {
    if (!world.gameWonOrLost) {
      current = CharacterState.deadGhost; //stops further interactions
      _ghostDeadTimeLatest = game.now;
      if (game.level.multipleSpawningGhosts && !spawningDeath) {
        removeFromParent();
      } else {
        if (spawningDeath) {
          /// can't call [disconnectSpriteFromBall] as body not yet initialised
          connectedToBall = false;
          if (world.level.homingGhosts) {
            _specialSpawnLocation = Vector2.all(0);
            _specialSpawnLocation!
                .setFrom(world.pacmans.pacmanList[0].position);
            add(MoveToPositionEffect(_specialSpawnLocation!));
          } else {
            add(MoveToPositionEffect(maze.ghostStart));
          }
        } else {
          disconnectFromBall();
          add(MoveToPositionEffect(maze.ghostStart));
        }
        add(RotateByAngleEffect(smallAngle(-angle)));
        //will get moved to right position later by code in sequence checker
      }
    }
  }

  void resetSlideAfterPacmanDeath() {
    disconnectFromBall();
    add(MoveToPositionEffect(maze.ghostStartForId(idNum)));
    add(RotateByAngleEffect(smallAngle(-angle)));
  }

  void resetInstantAfterPacmanDeath() {
    setPositionStill(maze.ghostStartForId(idNum));
    angle = 0;
    _ghostDeadTimeLatest = 0;
  }

  void _ghostDeadScaredScaredIshNormalSequence() {
    if (current == CharacterState.deadGhost) {
      if (game.now - _ghostDeadTimeLatest > kGhostResetTimeMillis) {
        if (!world.gameWonOrLost && _ghostDeadTimeLatest != 0) {
          //dont set on game over or after pacman death
          if (_specialSpawnLocation != null) {
            setPositionStill(_specialSpawnLocation!);
            _specialSpawnLocation = null;
          } else {
            setPositionStill(maze.ghostStart + Vector2.random() / 100);
          }
        }
        current = CharacterState.scared;
      }
    }
    if (current == CharacterState.scared) {
      if (game.now - world.ghosts.scaredTimeLatest >
          kGhostChaseTimeMillis * 2 / 3) {
        current = CharacterState.scaredIsh;
      }
    }

    if (current == CharacterState.scaredIsh) {
      if (game.now - world.ghosts.scaredTimeLatest > kGhostChaseTimeMillis) {
        current = CharacterState.normal;
        game.audioController.stopSfx(SfxType.ghostsScared);
      }
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    world.ghosts.ghostList.add(this);
    animations = await _getAnimations();
    current = CharacterState.deadGhost;
    if (idNum >= 3) {
      setDead(spawningDeath: true);
    }
  }

  @override
  Future<void> onRemove() async {
    world.ghosts.ghostList.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    _ghostDeadScaredScaredIshNormalSequence();
    super.update(dt);
  }
}
