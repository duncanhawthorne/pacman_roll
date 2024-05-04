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
    as dhpointer_move_event;

import '../../audio/sounds.dart';
import 'game_screen.dart';
import 'components/player.dart';
import 'components/maze.dart';
import 'components/maze_image.dart';
import 'constants.dart';
import 'helper.dart';

import 'package:sensors_plus/sensors_plus.dart';

import 'package:flutter/foundation.dart';

import '../audio/audio_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audioplayers/audioplayers.dart';

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
    with TapCallbacks, HasGameReference, DragCallbacks, PointerMoveCallbacks {
  EndlessWorld({
    required this.level,
    required this.playerProgress,
    Random? random,
  }) : _random = random ?? Random();

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
  late final DateTime timeStarted;
  Vector2 get size => (parent as FlameGame).size;

  int levelCompletedIn = 0;
  late final AudioController audioController;
  get getAudioController => audioController;
  int pelletsRemaining = 1;
  Vector2 dragLastPosition = Vector2(0, 0);
  Vector2 targetFromLastDrag = Vector2(-50, 0); //makes smooth start for drag
  double dragLastAngle = 10;
  double targetAngle = 2 * pi / 4;
  int now = 1;
  int levelCompleteTimeMillis = 0;
  int lastNewGhostTimeMillis = 0;
  int lastSirenVolumeUpdateTimeMillis = 0;

  /// The random number generator that is used to spawn periodic components.
  // ignore: unused_field
  final Random _random;

  /// The gravity is defined in virtual pixels per second squared.
  /// These pixels are in relation to how big the [FixedResolutionViewport] is.
  //@override
  //final Vector2 gravity = Vector2(0, 100);
  //Vector2 get worldGravity => gravity; //_worldGravity;
  //Vector2 _worldGravity = Vector2(0, 0); //initial value which immediately gets overridden
  //double get worldAngle => _worldAngle;
  //set worldAngle(double value) {_worldAngle = value;};
  double worldAngle = 0; //2 * pi / 8;
  double worldCos = 1;
  double worldSin = 0;

  /// Where the ground is located in the world and things should stop falling.
  //late final double groundLevel = (size.y / 2) - (size.y / 5);

  List<RealCharacter> ghostPlayersList = [];
  List<RealCharacter> pacmanPlayersList = [];

  Future<bool> loadAllAudioFiles() async {
    for (var type in SfxType.values) {
      loadAudioFile(type);
    }
    return true;
  }

  Future<bool> loadAudioFile(SfxType type) async {
    if (!audioPlayerMap.keys.contains(type)) {
      String filename = soundTypeToFilename(type)[0];
      AudioPlayer dAudioPlayerTmp = AudioPlayer();
      await dAudioPlayerTmp.setSource(AssetSource('sfx/$filename'));
      if (true) {
        //HACK to try to get around web sites not being able to play audio on delay
        dAudioPlayerTmp.setVolume(0);
        await dAudioPlayerTmp.stop();
        dAudioPlayerTmp.resume();
        dAudioPlayerTmp.pause();
        dAudioPlayerTmp.setVolume(1);
      }
      if (!audioPlayerMap.keys.contains(type)) {
        audioPlayerMap[type] = dAudioPlayerTmp;
      }
    }
    return true;
  }

  bool isGameLive() {
    return gameRunning && !game.paused && game.isLoaded && game.isMounted;
  }

  void play(SfxType type) async {
    if (soundsOn) {
      if (!audioPlayerMap.keys.contains(type)) {
        await loadAudioFile(type);
        Future.delayed(const Duration(milliseconds: 10), () {
          play(type);
        });
        return;
      }
      if (audioPlayerMap[type] != null) {
        audioPlayerMap[type]!.setPlayerMode(PlayerMode.lowLatency);
      } else {
        p(["audioPlayerMap[type] null", type]);
      }
      if (type == SfxType.ghostsScared) {
        audioPlayerMap[type]!.setReleaseMode(ReleaseMode.loop);
      }
      if (type == SfxType.siren) {
        audioPlayerMap[type]!.setReleaseMode(ReleaseMode.loop);
        updateSirenVolume();
      }
      if (!pelletEatSoundOn && type == SfxType.waka ||
          !sirenOn && type == SfxType.siren) {
        return;
      }
      if (audioPlayerMap[type]!.state != PlayerState.playing) {
        audioPlayerMap[type]!.seek(const Duration(milliseconds: 0));
        await audioPlayerMap[type]!.resume();
      }
    }
  }

  double getTargetSirenVolume() {
    double tmpSirenVolume = 0;
    try {
      for (int i = 0; i < ghostPlayersList.length; i++) {
        tmpSirenVolume += ghostPlayersList[i].current == CharacterState.normal
            ? ghostPlayersList[i].getUnderlyingBallVelocity().length /
                ghostPlayersList.length
            : 0;
      }
      if ((pacmanPlayersList.isNotEmpty &&
              pacmanPlayersList[0].current == CharacterState.deadPacman) ||
          !globalPhysicsLinked) {
        tmpSirenVolume = 0;
      }
    }
    // ignore: empty_catches
    catch (e) {
      tmpSirenVolume = 0;
      p([e, "tmpSirenVolume zero"]);
    }
    tmpSirenVolume = tmpSirenVolume / 30;
    if (tmpSirenVolume < 0.05) {
      tmpSirenVolume = 0;
    }
    tmpSirenVolume = min(0.4, tmpSirenVolume);
    if (!isGameLive()) {
      tmpSirenVolume = 0;
    }
    //p(tmpSirenVolume);
    return tmpSirenVolume;
  }

  void updateSirenVolume() async {
    //FIXME NOTE disabled on iOS for bug
    audioPlayerMap[SfxType.siren]!.setVolume(getTargetSirenVolume());
  }

  void deadMansSwitch() async {
    //FIXME note works as separate thread to stop all audio too, so dont disable
    if (isGameLive()) {
      Future.delayed(const Duration(milliseconds: 500), () {
        deadMansSwitch();
      });
    } else {
      stopAllAudio(); //for good measure
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

  void addGhost(int number) {
    RealCharacter ghost = RealCharacter(
        isGhost: true,
        startingPosition: kGhostStartLocation +
            Vector2(
                getSingleSquareWidth() * number <= 2 ? (number - 1) : 0, 0));
    ghost.ghostNumberForSprite = number;
    if (multiGhost && ghostPlayersList.isNotEmpty) {
      //new ghosts are also scared
      ghost.ghostScaredTimeLatest = ghostPlayersList[0].ghostScaredTimeLatest;
      ghost.current = CharacterState
          .deadGhost; //and then will get sequenced to correct state
    }
    add(ghost);
    ghostPlayersList.add(ghost);
    lastNewGhostTimeMillis = getNow();
  }

  void addPacman(Vector2 startPosition) {
    RealCharacter tmpPlayer =
        RealCharacter(isGhost: false, startingPosition: startPosition);
    add(tmpPlayer);
    pacmanPlayersList.add(tmpPlayer);
  }

  void removePacman(RealCharacter pacman) {
    remove(pacman.underlyingBallReal);
    remove(pacman);
    pacmanPlayersList.remove(pacman);
  }

  void removeGhost(RealCharacter ghost) {
    remove(ghost.underlyingBallReal);
    remove(ghost);
    ghostPlayersList.remove(ghost);
  }

  @override
  Future<void> onLoad() async {
    //stopAllAudio();
    now = DateTime.now().millisecondsSinceEpoch;
    gameRunning = true;
    loadAllAudioFiles();
    levelCompleteTimeMillis = 0;
    AudioLogger.logLevel = AudioLogLevel.info;
    if (sirenOn) {
      play(SfxType.siren);
    }
    pelletsRemaining = getStartingNumberPelletsAndSuperPellets(mazeLayout);
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

    //player =
    //    RealCharacter(isGhost: false, startingPosition: kPacmanStartLocation);
    //add(player);
    addPacman(kPacmanStartLocation);
    //addPacman(this, kPacmanStartLocation + Vector2.random() / 100);
    //addPacman(this, kPacmanStartLocation + Vector2.random() / 100);

    for (int i = 0; i < 3; i++) {
      addGhost(i);
    }

    if (!debugMode) {
      createMaze(this);
    }

    add(MazeImage());
    addPillsAndPowerPills(this);

    //add(Compass());

    // When the player takes a new point we check if the score is enough to
    // pass the level and if it is we calculate what time the level was passed
    // in, update the player's progress and open up a dialog that shows that
    // the player passed the level.
    scoreNotifier.addListener(() {
      if (scoreNotifier.value >= level.winScore) {
        final levelTime = getLevelTime();

        levelCompletedIn = levelTime.round();

        playerProgress.setLevelFinished(level.number, levelCompletedIn);
        game.pauseEngine();
        game.overlays.add(GameScreen.winDialogKey);
      }
    });
  }

  double getLevelTime() {
    return ((levelCompleteTimeMillis == 0
                ? getNow()
                : levelCompleteTimeMillis) -
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
  void onPointerMove(dhpointer_move_event.PointerMoveEvent event) {
    Vector2 eventVector = actuallyMoveSpritesToScreenPos
        ? event.localPosition
        : event.canvasPosition - game.canvasSize / 2;
    if (followCursor) {
      linearCursorMoveToGravity(Vector2(eventVector.x, eventVector.y));
    }
  }

  int getNow() {
    return now;
  }

  @override
  void update(double dt) {
    super.update(dt);
    now = DateTime.now().millisecondsSinceEpoch;

    if (multiGhost &&
        pelletsRemaining > 0 &&
        lastNewGhostTimeMillis != 0 &&
        getNow() - lastNewGhostTimeMillis > 5000) {
      addGhost(100);
    }
    if (getNow() - lastSirenVolumeUpdateTimeMillis > 500) {
      lastSirenVolumeUpdateTimeMillis = getNow();
      updateSirenVolume();
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    Vector2 eventVector = actuallyMoveSpritesToScreenPos
        ? event.localPosition
        : event.canvasPosition - game.canvasSize / 2;
    if (clickAndDrag) {
      if (iOS) {
        dragLastPosition = Vector2(0, 0);
        dragLastAngle = 10;
      } else {
        dragLastPosition = Vector2(eventVector.x, eventVector.y);
        dragLastAngle = atan2(eventVector.x, eventVector.y);
      }
    } else if (followCursor) {
      linearCursorMoveToGravity(Vector2(eventVector.x, eventVector.y));
    }
  }

  double convertToSmallestDeltaAngle(double angleDelta) {
    //avoid indicating  +2*pi-delta jump when go around the circle, instead give -delta
    angleDelta = angleDelta + 2 * pi / 2;
    angleDelta = angleDelta % (2 * pi);
    return angleDelta - 2 * pi / 2;
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
      // ignore: dead_code
      if (false && dragLastPosition != Vector2(0, 0)) {
        Vector2 dragDelta = -(eventVector - dragLastPosition);
        linearCursorMoveToGravity(targetFromLastDrag + dragDelta);
        targetFromLastDrag = targetFromLastDrag + dragDelta;
      }
      if (dragLastAngle != 10) {
        double spinMultiplier = 4 * min(1, eventVectorLengthProportion / 0.75);
        double currentAngleTmp = atan2(eventVector.x, eventVector.y);
        double angleDelta =
            convertToSmallestDeltaAngle(currentAngleTmp - dragLastAngle);
        targetAngle = targetAngle + angleDelta * spinMultiplier;
        setGravity(Vector2(cos(targetAngle), sin(targetAngle)));
      }
      dragLastPosition = Vector2(eventVector.x, eventVector.y);
      dragLastAngle = atan2(eventVector.x, eventVector.y);
    } else if (followCursor) {
      linearCursorMoveToGravity(Vector2(eventVector.x, eventVector.y));
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (clickAndDrag) {
      dragLastPosition = Vector2(0, 0);
      dragLastAngle = 10;
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
        worldCos = cos(worldAngle);
        worldSin = sin(worldAngle);
      }
    }
  }
}
