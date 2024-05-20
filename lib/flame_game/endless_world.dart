import 'dart:async';
import 'dart:math';

import 'package:flame_forge2d/flame_forge2d.dart';

import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
// ignore: implementation_imports
//import 'package:flame/src/events/messages/pointer_move_event.dart'
//    as flame_pointer_move_event;

import '../../audio/sounds.dart';
import 'game_screen.dart';
import 'endless_runner.dart';
import 'components/game_character.dart';
import 'components/maze_layout.dart';
import 'components/pacman.dart';
import 'components/ghost.dart';
import 'constants.dart';
import 'helper.dart';
import 'package:flutter/foundation.dart';
import 'dart:async' as async;

/// The world is where you place all the components that should live inside of
/// the game, like the player, enemies, obstacles and points for example.
/// The world can be much bigger than what the camera is currently looking at,
/// but in this game all components that go outside of the size of the viewport
/// are removed, since the player can't interact with those anymore.
///
/// The [EndlessWorld] has two mixins added to it:
///  - The [TapCallbacks] that makes it possible to react to taps (or mouse
///  clicks) on the world.
///  - The [HasGameReference] that gives the world access to a variable called
///  `game`, which is a reference to the game class that the world is attached
///  to.
class EndlessWorld extends Forge2DWorld
    with
        //TapCallbacks,
        HasGameReference<EndlessRunner>,
        //PointerMoveCallbacks,
        DragCallbacks {
  EndlessWorld({
    required this.level,
    required this.playerProgress,
    Random? random,
  }) : random = random ?? Random();

  /// The properties of the current level.
  final GameLevel level;

  /// Used to see what the current progress of the player is and to update the
  /// progress if a level is finished.
  final PlayerProgress playerProgress;

  final numberOfDeaths = ValueNotifier(0);
  final pelletsRemainingNotifier = ValueNotifier(0);
  int allGhostScaredTimeLatest = 0;

  int _datetimeStartedMillis = -1;
  int now = -1;
  int _levelCompleteTimeMillis = -1;
  //Vector2 get size => (parent as FlameGame).size;

  double _lastDragAngle = 10;
  double _gravityTargetAngle = 2 * pi / 4;
  bool _timerSet = false;

  final Random random;

  bool physicsOn = true;

  /// The gravity is defined in virtual pixels per second squared.
  /// These pixels are in relation to how big the [FixedResolutionViewport] is.

  List<Ghost> ghostPlayersList = [];
  List<Pacman> pacmanPlayersList = [];

  void play(SfxType type) {
    if (soundOn) {
      game.audioController.playSfx(type);
    }
  }

  bool gameWonOrLost() {
    return pelletsRemainingNotifier.value <= 0 ||
        numberOfDeaths.value >= level.maxAllowedDeaths;
  }

  String secondsElapsedText() {
    return !_timerSet
        ? "0.0"
        : ((now - _datetimeStartedMillis) / 1000).toStringAsFixed(1);
  }

  void sirenVolumeUpdatedTimer() async {
    //NOTE disabled on iOS due to bug
    async.Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (game.isGameLive()) {
        game.audioController.setSirenVolume(getTargetSirenVolume(this));
      } else {
        timer.cancel();
      }
    });
  }

  void addGhost(int ghostSpriteChooserNumber) {
    Vector2 target = kGhostStartLocation +
        Vector2(
            getSingleSquareWidth() *
                (ghostSpriteChooserNumber <= 2
                    ? (ghostSpriteChooserNumber - 1)
                    : 0),
            0);
    Ghost ghost = Ghost(position: target);
    ghost.ghostSpriteChooserNumber = ghostSpriteChooserNumber;
    if (multipleSpawningGhosts && ghostPlayersList.isNotEmpty) {
      //new ghosts are also scared
      ghost.current =
          CharacterState.scared; //and then will get sequenced to correct state
    }
    add(ghost);
  }

  void multiGhostAdderTimer() {
    if (multipleSpawningGhosts) {
      async.Timer.periodic(const Duration(milliseconds: 5000), (timer) {
        if (game.isGameLive()) {
          if (!gameWonOrLost()) {
            addGhost(100);
          }
        } else {
          timer.cancel();
        }
      });
    }
  }

  void trimToThreeGhosts() {
    int origNumGhosts = ghostPlayersList.length;
    for (int i = 0; i < origNumGhosts; i++) {
      int j = origNumGhosts - 1 - i;
      if (j < 3) {
      } else {
        assert(multipleSpawningGhosts);
        remove(ghostPlayersList[j]);
      }
    }
  }

  void handleWinGame() {
    if (game.isGameLive()) {
      if (pelletsRemainingNotifier.value == 0) {
        _levelCompleteTimeMillis = now;
        if (getLevelCompleteTimeSeconds() > 10) {
          save.firebasePushSingleScore(game.userString, game.getEncodeCurrentGameState());
        }
        game.overlays.remove(GameScreen.statusOverlay);
        game.overlays.remove(GameScreen.backButtonKey);
        game.overlays.add(GameScreen.wonDialogKey);
        trimToThreeGhosts();
        for (int i = 0; i < ghostPlayersList.length; i++) {
          ghostPlayersList[i].setPositionForGameEnd();
        }
        Future.delayed(
            const Duration(milliseconds: kPacmanHalfEatingResetTimeMillis * 2),
            () {
          play(SfxType.endMusic);
        });
      }
    }
  }

  void winOrLoseGameListener() {
    numberOfDeaths.addListener(() {
      if (numberOfDeaths.value >= level.maxAllowedDeaths) {
        handleLoseGame();
      }
    });
    pelletsRemainingNotifier.addListener(() {
      if (pelletsRemainingNotifier.value == 0) {
        handleWinGame();
      }
      if (pelletsRemainingNotifier.value == 5) {
        game.cacheLeaderboard(); //close to the end but not at the end
      }
    });
  }

  void handleLoseGame() {
    //playerProgress.setLevelFinished(level.number, getCurrentOrCompleteLevelTimeSeconds().toInt());
    game.pauseEngine();
    game.overlays.add(GameScreen.loseDialogKey);
    game.overlays.remove(GameScreen.statusOverlay);
    game.overlays.remove(GameScreen.backButtonKey);
  }

  double getLevelCompleteTimeSeconds() {
    assert(_levelCompleteTimeMillis != -1);
    return (_levelCompleteTimeMillis - _datetimeStartedMillis) / 1000;
  }

  void startTimer() {
    if (!_timerSet) {
      _timerSet = true;
      _datetimeStartedMillis = now;
    }
  }

  @override
  Future<void> onLoad() async {
    _timerSet = false;
    now = DateTime.now().millisecondsSinceEpoch;
    //datetimeStartedMillis = now;
    // Used to keep track of when the level started, so that we later can
    // calculate how long time it took to finish the level.
    _levelCompleteTimeMillis = -1;

    play(SfxType.startMusic);
    if (sirenEnabled) {
      play(SfxType.ghostsRoamingSiren);
      game.audioController.setSirenVolume(0);
      sirenVolumeUpdatedTimer();
    }

    add(Pacman(position: kPacmanStartLocation));
    for (int i = 0; i < 3; i++) {
      addGhost(i);
    }
    addAll(mazeWalls());
    addAll(screenEdgeBoundaries(game.camera));
    addAll(pelletsAndSuperPellets(pelletsRemainingNotifier));

    multiGhostAdderTimer();
    winOrLoseGameListener();
    handleAcceleratorEvents(this);
  }

  @override
  void onMount() {
    super.onMount();
    // When the world is mounted in the game we add a back button widget as an
    // overlay so that the player can go back to the previous screen.
    gameRunning = true;
    setStatusBarColor(palette.flameGameBackground.color);
    game.overlays.add(GameScreen.backButtonKey);
    game.overlays.add(GameScreen.statusOverlay);
  }

  @override
  void onRemove() {
    gameRunning = false;
    game.overlays.remove(GameScreen.backButtonKey);
    game.overlays.remove(GameScreen.statusOverlay);
    setStatusBarColor(palette.backgroundMain.color);
    game.audioController.stopAllSfx();
  }

  void addDeath({int amount = 1}) {
    numberOfDeaths.value += amount;
  }

  void resetDeaths() {
    numberOfDeaths.value -= 3;
  }

  /*
  @override
  void onPointerMove(flame_pointer_move_event.PointerMoveEvent event) {
    //TODO try to capture mouse on windows
    Vector2 eventVector = event.canvasPosition - game.canvasSize / 2;
    if (followCursor) {
      linearCursorMoveToGravity(Vector2(eventVector.x, eventVector.y));
    }
  }
   */

  @override
  void update(double dt) {
    super.update(dt);
    now = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    startTimer(); //starts off timer first time drag
    Vector2 eventVector = event.canvasPosition - game.canvasSize / 2;
    if (clickAndDrag) {
      if (iOS) {
        _lastDragAngle = 10;
      } else {
        _lastDragAngle = atan2(eventVector.x, eventVector.y);
      }
    } else if (followCursor) {
      linearCursorMoveToGravity(Vector2(eventVector.x, eventVector.y));
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    Vector2 eventVector = event.canvasStartPosition - game.canvasSize / 2;
    double eventVectorLengthProportion =
        (event.canvasStartPosition - game.canvasSize / 2).length /
            (min(game.canvasSize.x, game.canvasSize.y) / 2);
    if (clickAndDrag) {
      if (_lastDragAngle != 10) {
        double spinMultiplier = 4 * min(1, eventVectorLengthProportion / 0.75);
        double currentAngleTmp = atan2(eventVector.x, eventVector.y);
        double angleDelta =
            convertToSmallestDeltaAngle(currentAngleTmp - _lastDragAngle);
        _gravityTargetAngle = _gravityTargetAngle + angleDelta * spinMultiplier;
        setGravity(Vector2(cos(_gravityTargetAngle), sin(_gravityTargetAngle)));
      }
      _lastDragAngle = atan2(eventVector.x, eventVector.y);
    } else if (followCursor) {
      linearCursorMoveToGravity(Vector2(eventVector.x, eventVector.y));
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (clickAndDrag) {
      _lastDragAngle = 10;
    }
  }

  void linearCursorMoveToGravity(Vector2 eventVector) {
    assert(screenRotates);
    if (physicsOn) {
      double impliedAngle = -eventVector.x /
          min(game.canvasSize.x, game.canvasSize.y) *
          pointerRotationSpeed;
      setGravity(Vector2(cos(impliedAngle), sin(impliedAngle)));
    }
  }

  void setGravity(Vector2 targetGravity) {
    if (physicsOn) {
      gravity = targetGravity;
      if (normaliseGravity) {
        gravity = gravity.normalized() * 50;
      }
      if (screenRotates) {
        game.camera.viewfinder.angle = -atan2(gravity.x, gravity.y);
      }
    }
  }
}
