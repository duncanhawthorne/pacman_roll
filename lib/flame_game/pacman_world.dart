import 'dart:async' as async;
import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../audio/sounds.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../style/palette.dart';
import '../utils/helper.dart';
import 'components/game_character.dart';
import 'components/ghost.dart';
import 'maze.dart';
import 'components/mini_pellet.dart';
import 'components/pacman.dart';
import 'components/physics_ball.dart';
import 'components/super_pellet.dart';
import 'components/wrapper_no_events.dart';
import 'effects/return_home_effect.dart';
import 'pacman_game.dart';

final bool iOS = defaultTargetPlatform == TargetPlatform.iOS;
const bool overlayMainMenu = true;
final bool _sirenEnabled = !iOS;

/// The world is where you place all the components that should live inside of
/// the game, like the player, enemies, obstacles and points for example.
/// The world can be much bigger than what the camera is currently looking at,
/// but in this game all components that go outside of the size of the viewport
/// are removed, since the player can't interact with those anymore.
///
/// The [PacmanWorld] has two mixins added to it:
///  - The [DragCallbacks] that makes it possible to react to taps and drags
///  (or mouse clicks) on the world.
///  - The [HasGameReference] that gives the world access to a variable called
///  `game`, which is a reference to the game class that the world is attached
///  to.
class PacmanWorld extends Forge2DWorld
    with
        //TapCallbacks,
        HasGameReference<PacmanGame>,
        //PointerMoveCallbacks,
        DragCallbacks {
  PacmanWorld({
    required this.level,
    required this.playerProgress,
    Random? random,
  }) : random = random ?? Random();

  /// The properties of the current level.
  final GameLevel level;

  /// Used to see what the current progress of the player is and to update the
  /// progress if a level is finished.
  final PlayerProgress playerProgress;

  final numberOfDeathsNotifier = ValueNotifier(0);
  final pelletsRemainingNotifier = ValueNotifier(0);
  final characterWrapper = CharacterWrapper();

  final pacmanDyingNotifier = ValueNotifier(0);

  bool get gameWonOrLost =>
      pelletsRemainingNotifier.value <= 0 ||
      numberOfDeathsNotifier.value >= level.maxAllowedDeaths;

  int allGhostScaredTimeLatest = 0;
  ValueNotifier<bool> doingLevelResetFlourish = ValueNotifier(false);

  int now = DateTime.now().millisecondsSinceEpoch;
  //Vector2 get size => (parent as FlameGame).size;

  final Map<int, double?> _fingersLastDragAngle = {};

  double _lastMazeAngle = 0;
  bool cameraRotateableOnPacmanDeathFlourish = true;

  final Random random;

  /// The gravity is defined in virtual pixels per second squared.
  /// These pixels are in relation to how big the [FixedResolutionViewport] is.

  List<Ghost> ghostPlayersList = [];
  List<Pacman> pacmanPlayersList = [];

  async.Timer? ghostTimer;
  async.Timer? sirenTimer;

  void play(SfxType type) {
    const soundOn = true; //!(windows && !kIsWeb);
    if (soundOn) {
      game.audioController.playSfx(type);
    }
  }

  int numberAlivePacman() {
    if (pacmanPlayersList.isEmpty) {
      return 0;
    }
    return pacmanPlayersList
        .map((Pacman pacman) =>
            pacman.current != CharacterState.deadPacman ? 1 : 0)
        .reduce((value, element) => value + element);
  }

  double _averageGhostSpeed() {
    if (!game.isGameLive ||
        numberAlivePacman() == 0 ||
        gameWonOrLost ||
        ghostPlayersList.isEmpty) {
      return 0;
    } else {
      return ghostPlayersList
              .map((Ghost ghost) => ghost.current == CharacterState.normal
                  ? ghost.getVelocity().length
                  : 0.0)
              .reduce((value, element) => value + element) /
          ghostPlayersList.length;
    }
  }

  void _sirenVolumeUpdatedTimer() async {
    // ignore: prefer_conditional_assignment
    if (_sirenEnabled) {
      if (sirenTimer == null && game.isGameLive && !gameWonOrLost) {
        sirenTimer =
            async.Timer.periodic(const Duration(milliseconds: 250), (timer) {
          if (game.isGameLive && !gameWonOrLost) {
            game.audioController
                .setSirenVolume(_averageGhostSpeed(), gradual: true);
          } else {
            game.audioController.setSirenVolume(0);
            timer.cancel();
            sirenTimer = null;
          }
        });
      }
    }
  }

  void _addThreeGhosts() {
    for (int i = 0; i < 3; i++) {
      characterWrapper.add(Ghost(idNum: i));
    }
  }

  void scareGhosts() {
    if (pelletsRemainingNotifier.value != 0) {
      play(SfxType.ghostsScared);
      for (Ghost ghost in ghostPlayersList) {
        ghost.setScared();
      }
    }
  }

  void _startMultiGhostAdderTimer() {
    if (game.level.multipleSpawningGhosts &&
        ghostTimer == null &&
        game.isGameLive &&
        !gameWonOrLost) {
      ghostTimer = async.Timer.periodic(
          Duration(milliseconds: level.ghostSpwanTimerLength * 1000), (timer) {
        if (game.isGameLive &&
            !gameWonOrLost &&
            !doingLevelResetFlourish.value) {
          characterWrapper.add(Ghost(idNum: 100));
        } else {
          timer.cancel();
          ghostTimer = null;
        }
      });
    }
  }

  void cancelMultiGhostAdderTimer() {
    if (game.level.multipleSpawningGhosts && ghostTimer != null) {
      ghostTimer!.cancel();
      ghostTimer = null;
    }
  }

  void _trimAllGhosts() {
    for (int i = 0; i < ghostPlayersList.length; i++) {
      int j = ghostPlayersList.length - 1 - i;
      if (j >= 0) {
        //assert(game.level.multipleSpawningGhosts);
        ghostPlayersList[j].removeFromParent();
      }
    }
  }

  void disconnectGhostsFromPhysics() {
    for (int i = 0; i < ghostPlayersList.length; i++) {
      ghostPlayersList[i].disconnectFromPhysics();
    }
  }

  void winGameWorldTidy() {
    allGhostScaredTimeLatest = 0;
    game.audioController.stopSfx(SfxType.ghostsScared);
    play(SfxType.endMusic);
    _trimAllGhosts();
    for (Ghost ghost in ghostPlayersList) {
      /// now defunct as [trimAllGhosts]
      ghost.setPositionForGameEnd();
    }
  }

  final bool _slideCharactersAfterPacmanDeath = true;
  void resetWorldAfterPacmanDeath(Pacman dyingPacman) {
    //reset ghost scared status. Shouldn't be relevant as just died
    game.audioController.stopSfx(SfxType.ghostsScared);
    allGhostScaredTimeLatest = 0;

    if (!gameWonOrLost) {
      if (_slideCharactersAfterPacmanDeath) {
        cameraRotateableOnPacmanDeathFlourish = false;
        dyingPacman.slideToStartPositionAfterDeath();
        for (Ghost ghost in ghostPlayersList) {
          ghost.slideToStartPositionAfterPacmanDeath();
        }
        game.camera.viewfinder.add(RotateHomeEffectAndReset(
            smallAngle(-_lastMazeAngle),
            onComplete: _resetWorldAfterPacmanDeathReal));
      } else {
        _resetWorldAfterPacmanDeathReal();
      }
    } else {
      doingLevelResetFlourish.value = false;
    }
  }

  void _resetWorldAfterPacmanDeathReal() {
    assert(pacmanPlayersList.length == 1);
    Pacman dyingPacman = pacmanPlayersList[0];
    cameraRotateableOnPacmanDeathFlourish = true;
    dyingPacman.setStartPositionAfterDeath();
    if (game.level.multipleSpawningGhosts) {
      _trimAllGhosts();
      _addThreeGhosts();
    } else {
      for (Ghost ghost in ghostPlayersList) {
        ghost.setStartPositionAfterPacmanDeath();
      }
    }
    _setMazeAngle(0);
    doingLevelResetFlourish.value = false;
  }

  void _startSiren() {
    if (_sirenEnabled) {
      play(SfxType.ghostsRoamingSiren);
      game.audioController.setSirenVolume(0);
      _sirenVolumeUpdatedTimer();
    }
  }

  void reset() {
    cancelMultiGhostAdderTimer();
    if (game.findByKey(ComponentKey.named('tutorial')) != null) {
      game.findByKey(ComponentKey.named('tutorial'))!.removeFromParent();
    }
    if (sirenTimer != null) {
      game.audioController.setSirenVolume(0);
      sirenTimer!.cancel();
      sirenTimer = null;
    }

    if (multipleSpawningPacmans) {
      for (Pacman pacman in pacmanPlayersList) {
        pacman.disconnectSpriteFromBall(); //sync
        pacman.removeFromParent(); //async
      }
      characterWrapper.add(Pacman(position: maze.pacmanStart));
    } else {
      if (pacmanPlayersList.isEmpty) {
        characterWrapper.add(Pacman(position: maze.pacmanStart));
      } else {
        pacmanPlayersList[0].setStartPositionAfterDeath();
      }
    }
    if (game.level.multipleSpawningGhosts) {
      for (Ghost ghost in ghostPlayersList) {
        ghost.disconnectSpriteFromBall(); //sync
        ghost.removeFromParent(); //async
      }
      _addThreeGhosts();
    } else {
      if (ghostPlayersList.isEmpty) {
        _addThreeGhosts();
      } else {
        for (Ghost ghost in ghostPlayersList) {
          ghost.setStartPositionAfterPacmanDeath();
        }
      }
    }

    for (Component child in children) {
      if (child is PelletWrapper) {
        child.removeFromParent();
      } else if (child is WallWrapper) {
      } else if (child is MiniPelletSprite ||
          child is MiniPelletCircle ||
          child is SuperPelletSprite ||
          child is SuperPelletCircle) {
        //defunct
        child.removeFromParent();
      } else if (child is PhysicsBall) {
        if (!pacmanPlayersList.contains(child.realCharacter) &&
            !ghostPlayersList.contains(child.realCharacter)) {
          // clean up any stray balls. Shouldn't be necessary
          debug("stray physics ball"); //FIXME
        }
      }
    }
    add(maze.pellets(pelletsRemainingNotifier, level.superPelletsEnabled));

    numberOfDeathsNotifier.value = 0;
    pacmanDyingNotifier.value = 0;
    _setMazeAngle(0);
  }

  void start() {
    play(SfxType.startMusic);
    _startSiren();
    //multiGhostAdderTimer();
    cameraRotateableOnPacmanDeathFlourish = true;
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!game.levelStarted && !game.mazeEverRotated && level.number == 1) {
        //if user hasn't worked out how to start by now, give a prompt
        add(
          TextComponent(
              text: '←←←←←←←←\n↓      ↑\n↓ Drag ↑\n↓      ↑\n→→→→→→→→',
              position: maze.cage,
              anchor: Anchor.center,
              textRenderer: TextPaint(
                style: const TextStyle(
                  backgroundColor: Palette.blueMaze,
                  fontSize: 3,
                  color: Palette.playSessionContrast,
                  fontFamily: 'Press Start 2P',
                ),
              ),
              key: ComponentKey.named('tutorial'),
              priority: 100),
        );
      }
    });
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(maze.mazeWalls());
    add(characterWrapper);
    //addAll(screenEdgeBoundaries(game.camera));
    if (!overlayMainMenu) {
      start();
    }
    game.winOrLoseGameListener(); //after have created pellets //isn't disposed so don't call on start
  }

  @override
  void update(double dt) {
    super.update(dt);
    now = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    Vector2 eventVector = event.canvasPosition - game.canvasSize / 2;
    if (iOS) {
      _fingersLastDragAngle[event.pointerId] = null;
    } else {
      _fingersLastDragAngle[event.pointerId] =
          atan2(eventVector.x, eventVector.y);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    Vector2 eventVector = event.canvasStartPosition - game.canvasSize / 2;
    double eventVectorLengthProportion =
        (event.canvasStartPosition - game.canvasSize / 2).length /
            (min(game.canvasSize.x, game.canvasSize.y) / 2);
    double currentAngleTmp = atan2(eventVector.x, eventVector.y);
    if (_fingersLastDragAngle.containsKey(event.pointerId)) {
      if (_fingersLastDragAngle[event.pointerId] != null) {
        double angleDelta = smallAngle(
            currentAngleTmp - _fingersLastDragAngle[event.pointerId]!);
        double spinMultiplier = 4 * min(1, eventVectorLengthProportion / 0.75);

        if (game.findByKey(ComponentKey.named('tutorial')) != null) {
          game.findByKey(ComponentKey.named('tutorial'))!.removeFromParent();
        }
        game.mazeEverRotated = true;

        _moveMazeAngleByDelta(angleDelta * spinMultiplier);
      }
      _fingersLastDragAngle[event.pointerId] = currentAngleTmp;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (_fingersLastDragAngle.containsKey(event.pointerId)) {
      _fingersLastDragAngle.remove(event.pointerId);
    }
  }

  void _moveMazeAngleByDelta(double angleDelta) {
    if (cameraRotateableOnPacmanDeathFlourish && game.isGameLive) {
      _setMazeAngle(_lastMazeAngle + angleDelta);

      if (!doingLevelResetFlourish.value) {
        game.stopwatch.start();
        _startMultiGhostAdderTimer();
        _sirenVolumeUpdatedTimer();
      }
    }
  }

  void _setMazeAngle(double angle) {
    _lastMazeAngle = angle;
    gravity = Vector2(cos(_lastMazeAngle + 2 * pi / 4),
            sin(_lastMazeAngle + 2 * pi / 4)) *
        50;
    game.camera.viewfinder.angle = angle;
  }
}
