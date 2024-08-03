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
import 'components/pacman.dart';
import 'components/wrapper_no_events.dart';
import 'effects/rotate_by_effect.dart';
import 'maze.dart';
import 'pacman_game.dart';

final bool _iOS = defaultTargetPlatform == TargetPlatform.iOS;
final bool _sirenEnabled = !_iOS;

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

  final noEventsWrapper = WrapperNoEvents();
  final pacmanWrapper = PacmanWrapper();
  final ghostWrapper = GhostWrapper();

  final pacmanDyingNotifier = ValueNotifier(0);

  bool get gameWonOrLost =>
      pelletsRemainingNotifier.value <= 0 ||
      numberOfDeathsNotifier.value >= level.maxAllowedDeaths;

  int allGhostScaredTimeLatest = 0;
  ValueNotifier<bool> doingLevelResetFlourish = ValueNotifier(false);

  int now = DateTime.now().millisecondsSinceEpoch;
  //Vector2 get size => (parent as FlameGame).size;

  final Map<int, double?> _fingersLastDragAngle = {};

  bool cameraRotateableOnPacmanDeathFlourish = true;

  final Random random;

  /// The gravity is defined in virtual pixels per second squared.
  /// These pixels are in relation to how big the [FixedResolutionViewport] is.

  final List<Ghost> ghostPlayersList = [];
  final List<Pacman> pacmanPlayersList = [];

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
              .map((Ghost ghost) =>
                  ghost.current == CharacterState.normal ? ghost.speed : 0.0)
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

  void _cancelSirenVolumeUpdatedTimer() {
    if (sirenTimer != null) {
      game.audioController.setSirenVolume(0);
      sirenTimer!.cancel();
      sirenTimer = null;
    }
  }

  void _addThreeGhosts() {
    for (int i = 0; i < 3; i++) {
      ghostWrapper.add(Ghost(idNum: i));
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
          ghostWrapper.add(Ghost(idNum: [3, 4, 5][random.nextInt(3)]));
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
        ghostPlayersList[j].removeFromParent();
      }
    }
  }

  void disconnectGhostsFromBalls() {
    for (int i = 0; i < ghostPlayersList.length; i++) {
      ghostPlayersList[i].disconnectFromBall();
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
        game.camera.viewfinder.add(RotateByAngleEffect(
            smallAngle(-game.camera.viewfinder.angle),
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

  void _showTutorial() {
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!game.levelStarted &&
          !game.mazeEverRotated &&
          game.findByKey(ComponentKey.named('tutorial')) == null &&
          level.number == 1) {
        //if user hasn't worked out how to start by now, give a prompt
        add(
          TextComponent(
              text: '←←←←←←←←\n↓      ↑\n↓ Drag ↑\n↓      ↑\n→→→→→→→→',
              position: maze.cage,
              anchor: Anchor.center,
              textRenderer: _tutorialTextRenderer,
              key: ComponentKey.named('tutorial'),
              priority: 100),
        );
      }
    });
  }

  void _removeTutorial() {
    if (game.findByKey(ComponentKey.named('tutorial')) != null) {
      game.findByKey(ComponentKey.named('tutorial'))!.removeFromParent();
    }
  }

  void _resetMaze() {
    for (Component child in noEventsWrapper.children) {
      if (child is PelletWrapper) {
        child.removeFromParent();
      } else if (child is WallWrapper) {
        child.removeFromParent();
      }
    }
    noEventsWrapper
        .add(maze.pellets(pelletsRemainingNotifier, level.superPelletsEnabled));
    noEventsWrapper.add(maze.mazeWalls());
  }

  void _resetPacmanLayer({bool mazeResize = false}) {
    if (multipleSpawningPacmans || mazeResize) {
      for (Pacman pacman in pacmanPlayersList) {
        pacman.disconnectFromBall(); //sync
        pacman.removeFromParent(); //async
      }
      pacmanWrapper.add(Pacman(position: maze.pacmanStart));
    } else {
      if (pacmanPlayersList.isEmpty) {
        pacmanWrapper.add(Pacman(position: maze.pacmanStart));
      } else {
        pacmanPlayersList[0].setStartPositionAfterDeath();
      }
    }
    numberOfDeathsNotifier.value = 0;
    pacmanDyingNotifier.value = 0;
  }

  void _resetGhostLayer({bool mazeResize = false}) {
    if (game.level.multipleSpawningGhosts || mazeResize) {
      for (Ghost ghost in ghostPlayersList) {
        ghost.disconnectFromBall(); //sync
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
  }

  void reset({bool mazeResize = false}) {
    cancelMultiGhostAdderTimer();
    _cancelSirenVolumeUpdatedTimer;
    _removeTutorial();
    _resetMaze();
    _resetPacmanLayer(mazeResize: mazeResize);
    _resetGhostLayer(mazeResize: mazeResize);
    _setMazeAngle(0);
    //cameraRotateableOnPacmanDeathFlourish = true; //perhaps not necessary
  }

  void start() {
    play(SfxType.startMusic);
    _showTutorial();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(noEventsWrapper);
    noEventsWrapper.add(pacmanWrapper);
    noEventsWrapper.add(ghostWrapper);
    game.winOrLoseGameListener(); //isn't disposed so run once, not on start()
  }

  @override
  void update(double dt) {
    super.update(dt);
    now = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_iOS) {
      _fingersLastDragAngle[event.pointerId] = null;
    } else {
      _fingersLastDragAngle[event.pointerId] = atan2(
          event.canvasPosition.x - game.canvasSize.x / 2,
          event.canvasPosition.y - game.canvasSize.y / 2);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    double eventVectorLengthProportion =
        (event.canvasStartPosition - game.canvasSize / 2).length /
            (min(game.canvasSize.x, game.canvasSize.y) / 2);
    double fingerCurrentDragAngle = atan2(
        event.canvasStartPosition.x - game.canvasSize.x / 2,
        event.canvasStartPosition.y - game.canvasSize.y / 2);
    if (_fingersLastDragAngle.containsKey(event.pointerId)) {
      if (_fingersLastDragAngle[event.pointerId] != null) {
        double angleDelta = smallAngle(
            fingerCurrentDragAngle - _fingersLastDragAngle[event.pointerId]!);
        double spinMultiplier = 4 * min(1, eventVectorLengthProportion / 0.75);

        if (!game.mazeEverRotated) {
          _removeTutorial();
          game.mazeEverRotated = true;
        }

        _moveMazeAngleByDelta(angleDelta * spinMultiplier);
      }
      _fingersLastDragAngle[event.pointerId] = fingerCurrentDragAngle;
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
      _setMazeAngle(game.camera.viewfinder.angle + angleDelta);

      if (!doingLevelResetFlourish.value) {
        game.stopwatch.start();
        _startMultiGhostAdderTimer();
        _sirenVolumeUpdatedTimer();
      }
    }
  }

  void _setMazeAngle(double angle) {
    gravity = Vector2(cos(angle + 2 * pi / 4), sin(angle + 2 * pi / 4)) *
        50 *
        (30 / flameGameZoom);
    game.camera.viewfinder.angle = angle;
  }
}

final TextPaint _tutorialTextRenderer = TextPaint(
  style: const TextStyle(
    backgroundColor: Palette.blueMaze,
    fontSize: 3,
    color: Palette.playSessionContrast,
    fontFamily: 'Press Start 2P',
  ),
);
