import 'dart:async';
import 'dart:math';

import 'package:flame_forge2d/flame_forge2d.dart';

import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
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
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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

  /// In the [scoreNotifier] we keep track of what the current score is, and if
  /// other parts of the code is interested in when the score is updated they
  /// can listen to it and act on the updated value.
  final scoreNotifier = ValueNotifier(0);
  //late RealCharacter player;
  DateTime timeStarted = DateTime.now();
  Vector2 get size => (parent as FlameGame).size;

  int levelCompletedIn = 0;
  int pelletsRemaining = 1;
  Vector2 lastDragPosition = Vector2(0, 0);
  double _lastDragAngle = 10;
  double gravityTargetAngle = 2 * pi / 4;
  int now = DateTime.now().millisecondsSinceEpoch;
  int levelCompleteTimeMillis = 0;
  int lastNewGhostTimeMillis = 0;
  int lastSirenVolumeUpdateTimeMillis = 0;

  /// The random number generator that is used to spawn periodic components.
  final Random random;

  /// The gravity is defined in virtual pixels per second squared.
  /// These pixels are in relation to how big the [FixedResolutionViewport] is.
  double worldAngle = 0; //2 * pi / 8;
  double worldCos = 1;
  double worldSin = 0;

  List<Ghost> ghostPlayersList = [];
  List<Pacman> pacmanPlayersList = [];

  bool isGameLive() {
    return gameRunning && !game.paused && game.isLoaded && game.isMounted;
  }

  void play(SfxType type) {
    if (soundOn) {
      game.audioController.playSfx(type);
    }
  }

  void updateSirenVolume() async {
    //NOTE disabled on iOS for bug
    if (sirenOn && now - lastSirenVolumeUpdateTimeMillis > 500) {
      lastSirenVolumeUpdateTimeMillis = now;
      game.audioController.setSirenVolume(getTargetSirenVolume(
          isGameLive(), ghostPlayersList, pacmanPlayersList));
    }
  }

  void deadMansSwitch() async {
    //Wworks as separate thread to stop all audio when game stops
    if (isGameLive()) {
      Future.delayed(const Duration(milliseconds: 500), () {
        deadMansSwitch();
      });
    } else {
      game.audioController.stopAllSfx();
    }
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
        return Vector2(worldCos * absolutePos[0] + -worldSin * absolutePos[1],
            worldSin * absolutePos[0] + worldCos * absolutePos[1]);
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
    lastNewGhostTimeMillis = now;
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

  void endOfGameTestAndAct() {
    if (isGameLive()) {
      if (pelletsRemaining == 0) {
        levelCompleteTimeMillis = now;
        if (getLevelTimeSeconds() > 10) {
          save.firebasePush(game.userString, game.getEncodeCurrentGameState());
        }
        game.overlays.add(GameScreen.wonDialogKey);
        trimToThreeGhosts();
        for (int i = 0; i < ghostPlayersList.length; i++) {
          ghostPlayersList[i]
              .setUnderlyingBallPosition(
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
    p("world on load");
    now = DateTime.now().millisecondsSinceEpoch;
    gameRunning = true;
    levelCompleteTimeMillis = 0;

    //p(scoreboardItems);

    //AudioLogger.logLevel = AudioLogLevel.info;
    if (sirenOn) {
      play(SfxType.ghostsRoamingSiren);
    }
    pelletsRemaining = getStartingNumberPelletsAndSuperPellets(flatMazeLayout);
    deadMansSwitch();

    WakelockPlus.toggle(enable: true);

    // Used to keep track of when the level started, so that we later can
    // calculate how long time it took to finish the level.
    timeStarted = DateTime.now();

    if (useGyro) {
      accelerometerEventStream().listen(
        //start once and then runs
        (AccelerometerEvent event) {
          setGravity(Vector2(event.y, event.x - 5) * (android && web ? 5 : 1));
        },
        onError: (error) {
          // Logic to handle error
          // Needed for Android in case sensor is not available
        },
        cancelOnError: true,
      );
    }

    addPacman(kPacmanStartLocation);

    for (int i = 0; i < 3; i++) {
      addGhost(i);
    }

    add(MazeImage());
    addMazeWalls(this);
    addPelletsAndSuperPellets(this);
    //add(Compass());

    // When the player takes a new point we check if the score is enough to
    // pass the level and if it is we calculate what time the level was passed
    // in, update the player's progress and open up a dialog that shows that
    // the player passed the level.
    scoreNotifier.addListener(() {
      if (scoreNotifier.value >= level.winScore) {
        final levelTime = getLevelTimeSeconds();

        levelCompletedIn = levelTime.round();

        playerProgress.setLevelFinished(level.number, levelCompletedIn);
        game.pauseEngine();
        game.overlays.add(GameScreen.loseDialogKey);
      }
    });
  }

  double getLevelTimeSeconds() {
    return ((levelCompleteTimeMillis == 0 ? now : levelCompleteTimeMillis) -
            timeStarted.millisecondsSinceEpoch) /
        1000;
  }

  @override
  void onMount() {
    super.onMount();
    // When the world is mounted in the game we add a back button widget as an
    // overlay so that the player can go back to the previous screen.
    gameRunning = true;
    game.overlays.add(GameScreen.backButtonKey);
  }

  @override
  void onRemove() {
    gameRunning = false;
    game.overlays.remove(GameScreen.backButtonKey);
  }

  /// Gives the player points, with a default value +1 points.
  void addScore({int amount = 1}) {
    scoreNotifier.value += amount;
  }

  /// Sets the player's score to 0 again.
  void resetScore() {
    scoreNotifier.value -= 3;
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

  void handleMultiGhost() {
    if (multipleSpawningGhosts &&
        pelletsRemaining > 0 &&
        lastNewGhostTimeMillis != 0 &&
        now - lastNewGhostTimeMillis > 5000) {
      addGhost(100);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    now = DateTime.now().millisecondsSinceEpoch;
    handleMultiGhost();
    updateSirenVolume();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    Vector2 eventVector = actuallyMoveSpritesToScreenPos
        ? event.localPosition
        : event.canvasPosition - game.canvasSize / 2;
    if (clickAndDrag) {
      if (iOS) {
        lastDragPosition = Vector2(0, 0);
        _lastDragAngle = 10;
      } else {
        lastDragPosition = Vector2(eventVector.x, eventVector.y);
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
        gravityTargetAngle = gravityTargetAngle + angleDelta * spinMultiplier;
        setGravity(Vector2(cos(gravityTargetAngle), sin(gravityTargetAngle)));
      }
      lastDragPosition = Vector2(eventVector.x, eventVector.y);
      _lastDragAngle = atan2(eventVector.x, eventVector.y);
    } else if (followCursor) {
      linearCursorMoveToGravity(Vector2(eventVector.x, eventVector.y));
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (clickAndDrag) {
      lastDragPosition = Vector2(0, 0);
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
          worldCos = cos(worldAngle);
          worldSin = sin(worldAngle);
        }
      }
    }
  }
}
