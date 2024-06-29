import 'dart:async' as async;
import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../audio/sounds.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../utils/helper.dart';
import 'components/game_character.dart';
import 'components/ghost.dart';
import 'components/maze.dart';
import 'components/pacman.dart';
import 'effects/return_home_effect.dart';
import 'pacman_game.dart';

final bool iOS = defaultTargetPlatform == TargetPlatform.iOS;

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

  final pacmanDyingNotifier = ValueNotifier(0);

  bool get gameWonOrLost =>
      pelletsRemainingNotifier.value <= 0 ||
      numberOfDeathsNotifier.value >= level.maxAllowedDeaths;

  int allGhostScaredTimeLatest = 0;

  int now = DateTime.now().millisecondsSinceEpoch;
  //Vector2 get size => (parent as FlameGame).size;

  final Map<int, double?> _fingersLastDragAngle = {};

  double _lastMazeAngle = 0;
  bool _cameraRotateable = true;

  final Random random;

  /// The gravity is defined in virtual pixels per second squared.
  /// These pixels are in relation to how big the [FixedResolutionViewport] is.

  List<Ghost> ghostPlayersList = [];
  List<Pacman> pacmanPlayersList = [];

  void play(SfxType type) {
    const soundOn = true; //!(windows && !kIsWeb);
    if (soundOn) {
      game.audioController.playSfx(type);
    }
  }

  int numberAlivePacman() {
    return pacmanPlayersList
        .map((Pacman pacman) =>
            pacman.current != CharacterState.deadPacman ? 1 : 0)
        .reduce((value, element) => value + element);
  }

  double averageGhostSpeed() {
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

  void sirenVolumeUpdatedTimer() async {
    //NOTE disabled on iOS due to bug
    async.Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (game.isGameLive) {
        game.audioController.setSirenVolume(averageGhostSpeed());
      } else {
        game.audioController.setSirenVolume(0);
        timer.cancel();
      }
    });
  }

  void addGhost(int idNum) {
    Vector2 target = maze.ghostStartForId(idNum);
    Ghost ghost = Ghost(position: target);
    ghost.idNum = idNum;
    add(ghost);
  }

  void addThreeGhosts() {
    for (int i = 0; i < 3; i++) {
      addGhost(i);
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

  void multiGhostAdderTimer() {
    if (multipleSpawningGhosts) {
      async.Timer.periodic(const Duration(milliseconds: 5000), (timer) {
        if (game.isGameLive) {
          if (!gameWonOrLost) {
            addGhost(100);
          }
        } else {
          timer.cancel();
        }
      });
    }
  }

  void trimAllGhosts() {
    for (int i = 0; i < ghostPlayersList.length; i++) {
      int j = ghostPlayersList.length - 1 - i;
      if (j >= 0) {
        //assert(multipleSpawningGhosts);
        remove(ghostPlayersList[j]);
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
    trimAllGhosts();
    for (Ghost ghost in ghostPlayersList) {
      /// now defunct as [trimAllGhosts]
      ghost.setPositionForGameEnd();
    }
  }

  final bool _gradualWorldReset = true;
  void resetWorldAfterPacmanDeath(Pacman dyingPacman) {
    //reset ghost scared status. Shouldn't be relevant as just died
    game.audioController.stopSfx(SfxType.ghostsScared);
    allGhostScaredTimeLatest = 0;

    if (!gameWonOrLost) {
      if (_gradualWorldReset) {
        _cameraRotateable = false;
        dyingPacman.slideToStartPositionAfterDeath();
        for (Ghost ghost in ghostPlayersList) {
          ghost.slideToStartPositionAfterPacmanDeath();
        }
        game.camera.viewfinder
            .add(RotateHomeEffect(smallAngle(-_lastMazeAngle)));

        Future.delayed(const Duration(milliseconds: kGhostResetTimeMillis), () {
          _cameraRotateable = true;
          _resetWorldAfterPacmanDeathReal(dyingPacman);
        });
      } else {
        _resetWorldAfterPacmanDeathReal(dyingPacman);
      }
    }
  }

  void _resetWorldAfterPacmanDeathReal(Pacman dyingPacman) {
    //_fingersLastDragAngle.clear(); //so you have to re-press
    dyingPacman.setStartPositionAfterDeath();
    if (multipleSpawningGhosts) {
      trimAllGhosts();
      addThreeGhosts();
    } else {
      for (Ghost ghost in ghostPlayersList) {
        ghost.setStartPositionAfterPacmanDeath();
      }
    }
    setMazeAngle(0);
  }

  void startSiren() {
    final bool sirenEnabled = !iOS;
    if (sirenEnabled) {
      play(SfxType.ghostsRoamingSiren);
      game.audioController.setSirenVolume(0);
      sirenVolumeUpdatedTimer();
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    play(SfxType.startMusic);
    startSiren();

    add(Pacman(position: maze.pacmanStart));
    addThreeGhosts();
    addAll(maze.mazeWalls());
    //addAll(screenEdgeBoundaries(game.camera));
    addAll(maze.pellets(pelletsRemainingNotifier, level.superPelletsEnabled));

    multiGhostAdderTimer();
    game.winOrLoseGameListener();
  }

  @override
  void update(double dt) {
    super.update(dt);
    now = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    game.stopwatch.start();
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
        moveMazeAngleByDelta(angleDelta * spinMultiplier);
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

  void moveMazeAngleByDelta(double angleDelta) {
    setMazeAngle(_lastMazeAngle + angleDelta);
  }

  void setMazeAngle(double angle) {
    if (_cameraRotateable) {
      _lastMazeAngle = angle;
      gravity = Vector2(cos(_lastMazeAngle + 2 * pi / 4),
              sin(_lastMazeAngle + 2 * pi / 4)) *
          50;
      game.camera.viewfinder.angle = angle;
    }
  }
}
