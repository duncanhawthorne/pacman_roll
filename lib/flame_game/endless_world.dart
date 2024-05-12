import 'dart:async';
import 'dart:math';

import 'package:flame_forge2d/flame_forge2d.dart';

import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:flame/src/events/messages/pointer_move_event.dart'
    as flame_pointer_move_event;

import '../../audio/sounds.dart';
import 'game_screen.dart';
import 'endless_runner.dart';
import 'components/game_character.dart';
import 'components/maze_walls.dart';
import 'components/maze_image.dart';
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
        DragCallbacks,
        PointerMoveCallbacks {
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

  /// In the [numberOfDeaths] we keep track of what the current score is, and if
  /// other parts of the code is interested in when the score is updated they
  /// can listen to it and act on the updated value.
  final numberOfDeaths = ValueNotifier(0);
  final pelletsRemainingNotifier = ValueNotifier(0);

  DateTime datetimeStarted = DateTime.now();
  int now = DateTime.now().millisecondsSinceEpoch;
  int _levelCompleteTimeMillis = 0;
  //Vector2 get size => (parent as FlameGame).size;

  //int levelCompletedIn = 0;
  //int pelletsRemaining = 1;
  double _lastDragAngle = 10;
  double _gravityTargetAngle = 2 * pi / 4;
  //int _lastNewGhostTimeMillis = 0;
  //int _lastSirenVolumeUpdateTimeMillis = 0;

  final Random random;

  /// The gravity is defined in virtual pixels per second squared.
  /// These pixels are in relation to how big the [FixedResolutionViewport] is.
  double worldAngle = 0; //2 * pi / 8;
  double _worldCos = 1;
  double _worldSin = 0;

  List<Ghost> ghostPlayersList = [];
  List<Pacman> pacmanPlayersList = [];

  void play(SfxType type) {
    if (soundOn) {
      game.audioController.playSfx(type);
    }
  }

  void sirenVolumeUpdatedTimer() async {
    //NOTE disabled on iOS for bug

    async.Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (game.isGameLive()) {
        game.audioController.setSirenVolume(getTargetSirenVolume(
            game.isGameLive(), ghostPlayersList, pacmanPlayersList));
      } else {
        timer.cancel();
      }
    });

    /*
    if (sirenEnabled && now - _lastSirenVolumeUpdateTimeMillis > 500) {
      _lastSirenVolumeUpdateTimeMillis = now;
      game.audioController.setSirenVolume(getTargetSirenVolume(
          game.isGameLive(), ghostPlayersList, pacmanPlayersList));
    }

     */
  }

  Vector2 screenPos(Vector2 absolutePos) {
    if (!actuallyMoveSpritesToScreenPos) {
      return absolutePos;
    } else {
      if (!screenRotates) {
        return absolutePos;
      } else {
        //Matrix2 mat = Matrix2(
        //    worldCos, -worldSin, worldSin, worldCos);
        return Vector2(_worldCos * absolutePos[0] + -_worldSin * absolutePos[1],
            _worldSin * absolutePos[0] + _worldCos * absolutePos[1]);
      }
    }
  }

  void addGhost(int ghostSpriteChooserNumber) {
    Ghost ghost = Ghost(
        position: kGhostStartLocation +
            Vector2(
                getSingleSquareWidth() * ghostSpriteChooserNumber <= 2
                    ? (ghostSpriteChooserNumber - 1)
                    : 0,
                0));
    ghost.ghostSpriteChooserNumber = ghostSpriteChooserNumber;
    if (multipleSpawningGhosts && ghostPlayersList.isNotEmpty) {
      //new ghosts are also scared
      ghost.ghostScaredTimeLatest = ghostPlayersList[0].ghostScaredTimeLatest;
      ghost.current = CharacterState
          .deadGhost; //and then will get sequenced to correct state
    }
    add(ghost);
    ghostPlayersList.add(ghost);
    //_lastNewGhostTimeMillis = now;
  }

  void addPacman(Vector2 startPosition) {
    Pacman tmpPlayer = Pacman(position: startPosition);
    add(tmpPlayer);
    pacmanPlayersList.add(tmpPlayer);
  }

  void removePacman(Pacman pacman) {
    remove(pacman.underlyingBallReal);
    remove(pacman);
    pacmanPlayersList.remove(pacman);
  }

  void removeGhost(Ghost ghost) {
    remove(ghost.underlyingBallReal);
    remove(ghost);
    ghostPlayersList.remove(ghost);
  }

  void multiGhostAdderTimer() {
    if (multipleSpawningGhosts) {
      int counter = 0;
      async.Timer.periodic(const Duration(milliseconds: 5000), (timer) {
        if (game.isGameLive()) {
          if (pelletsRemainingNotifier.value > 0 && counter > 0) {
            addGhost(100);
          }
        } else {
          timer.cancel();
        }
        counter++;
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
        ghostPlayersList[j].ghostScaredTimeLatest = 0;
        removeGhost(ghostPlayersList[j]);
      }
    }
  }

  void removePellet(PositionComponent pellet) {
    pellet.removeFromParent();
    pelletsRemainingNotifier.value -= 1;
    //world.endOfGameTestAndAct(); //now handled via valuelistener
  }

  void endOfGameTestAndAct() {
    if (game.isGameLive()) {
      if (pelletsRemainingNotifier.value == 0) {
        _levelCompleteTimeMillis = now;
        if (getCurrentOrCompleteLevelTimeSeconds() > 10) {
          save.firebasePush(game.userString, game.getEncodeCurrentGameState());
        }
        game.overlays.remove(GameScreen.statusOverlay);
        game.overlays.remove(GameScreen.backButtonKey);
        game.overlays.add(GameScreen.wonDialogKey);
        trimToThreeGhosts();
        for (int i = 0; i < ghostPlayersList.length; i++) {
          ghostPlayersList[i].setUnderlyingBallPosition(
              kCageLocation + Vector2.random() / 100);
        }
        Future.delayed(
            const Duration(milliseconds: kPacmanHalfEatingResetTimeMillis * 2),
            () {
          play(SfxType.endMusic);
        });
      }
    }
  }

  @override
  Future<void> onLoad() async {
    datetimeStarted = DateTime.now();
    now = DateTime.now().millisecondsSinceEpoch;
    _levelCompleteTimeMillis = 0;
    // Used to keep track of when the level started, so that we later can
    // calculate how long time it took to finish the level.

    play(SfxType.startMusic);
    if (sirenEnabled) {
      play(SfxType.ghostsRoamingSiren);
      sirenVolumeUpdatedTimer();
    }

    addPacman(kPacmanStartLocation);
    for (int i = 0; i < 3; i++) {
      addGhost(i);
    }
    multiGhostAdderTimer();
    add(MazeImage());
    addMazeWalls(this);
    addAll(createBoundaries(game.camera));
    addPelletsAndSuperPellets(this, pelletsRemainingNotifier);

    numberOfDeaths.addListener(() {
      if (numberOfDeaths.value >= level.maxAllowedDeaths) {
        //playerProgress.setLevelFinished(level.number, getCurrentOrCompleteLevelTimeSeconds().toInt());
        game.pauseEngine();
        game.overlays.add(GameScreen.loseDialogKey);
      }
    });
    pelletsRemainingNotifier.addListener(() {
      if (pelletsRemainingNotifier.value == 0) {
        endOfGameTestAndAct();
      }
    });

    handleAcceleratorEvents(this);
  }

  double getCurrentOrCompleteLevelTimeSeconds() {
    return ((_levelCompleteTimeMillis == 0 ? now : _levelCompleteTimeMillis) -
            datetimeStarted.millisecondsSinceEpoch) /
        1000;
  }

  @override
  void onMount() {
    super.onMount();
    // When the world is mounted in the game we add a back button widget as an
    // overlay so that the player can go back to the previous screen.
    gameRunning = true;
    game.overlays.add(GameScreen.backButtonKey);
    game.overlays.add(GameScreen.statusOverlay);
  }

  @override
  void onRemove() {
    gameRunning = false;
    game.overlays.remove(GameScreen.backButtonKey);
    game.overlays.remove(GameScreen.statusOverlay);
  }

  void addDeath({int amount = 1}) {
    numberOfDeaths.value += amount;
  }

  void resetDeaths() {
    numberOfDeaths.value -= 3;
  }

  @override
  void onPointerMove(flame_pointer_move_event.PointerMoveEvent event) {
    //TODO try to capture mouse on windows
    Vector2 eventVector = actuallyMoveSpritesToScreenPos
        ? event.localPosition
        : event.canvasPosition - game.canvasSize / 2;
    if (followCursor) {
      linearCursorMoveToGravity(Vector2(eventVector.x, eventVector.y));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    now = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    Vector2 eventVector = actuallyMoveSpritesToScreenPos
        ? event.localPosition
        : event.canvasPosition - game.canvasSize / 2;
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
    Vector2 eventVector = actuallyMoveSpritesToScreenPos
        ? event.localStartPosition
        : event.canvasStartPosition - game.canvasSize / 2;
    double eventVectorLengthProportion = actuallyMoveSpritesToScreenPos
        ? event.localStartPosition.length / (inGameVectorPixels / 2)
        : (event.canvasStartPosition - game.canvasSize / 2).length /
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
    if (globalPhysicsLinked) {
      double impliedAngle = -eventVector.x /
          (actuallyMoveSpritesToScreenPos
              ? inGameVectorPixels
              : min(game.canvasSize.x, game.canvasSize.y)) *
          pointerRotationSpeed;
      setGravity(Vector2(cos(impliedAngle), sin(impliedAngle)));
    }
  }

  void setGravity(Vector2 targetGravity) {
    if (globalPhysicsLinked) {
      gravity = targetGravity;
      if (normaliseGravity) {
        gravity = gravity.normalized() * 50;
      }
      if (screenRotates) {
        worldAngle = atan2(gravity.x, gravity.y);
        if (actuallyMoveSpritesToScreenPos) {
          _worldCos = cos(worldAngle);
          _worldSin = sin(worldAngle);
        }
      }
    }
  }
}
