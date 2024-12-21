import 'dart:async' as async;
import 'dart:core';
import 'dart:math';
import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../app_lifecycle/app_lifecycle.dart';
import '../audio/audio_controller.dart';
import '../firebase/firebase_saves.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../style/palette.dart';
import '../utils/helper.dart';
import '../utils/src/workarounds.dart';
import '../utils/stored_moves.dart';
import 'game_screen.dart';
import 'maze.dart';
import 'pacman_world.dart';

/// This is the base of the game which is added to the [GameWidget].
///
/// This class defines a few different properties for the game:
///  - That it should have a [FixedResolutionViewport] containing
///  a square of size [kVirtualGameSize]
///  this means that even if you resize the window, the square itself will keep
///  the defined virtual resolution.
///  - That the default world that the camera is looking at should be the
///  [PacmanWorld].
///
/// Note that both of the last are passed in to the super constructor, they
/// could also be set inside of `onLoad` for example.

// flame_forge2d has a maximum allowed speed for physical objects.
// Reducing map size 30x, scaling up gravity 30x, & zooming 30x changes nothing,
// but reduces chance of hitting maximum allowed speed
const double flameGameZoom = 30.0;
const double _visualZoomMultiplier = 0.92;
const double kVirtualGameSize = 1700; //determines speed of game

class PacmanGame extends Forge2DGame<PacmanWorld>
    with
        // ignore: always_specify_types
        HasQuadTreeCollisionDetection,
        SingleGameInstance,
        HasTimeScale {
  PacmanGame({
    required this.level,
    required int mazeId,
    required this.playerProgress,
    required this.audioController,
    required this.appLifecycleStateNotifier,
  }) : super(
          world: PacmanWorld(),
          camera: CameraComponent.withFixedResolution(
              width: kVirtualGameSize, height: kVirtualGameSize),
          zoom: flameGameZoom * _visualZoomMultiplier,
        ) {
    this.mazeId = mazeId;
  }

  /// What the properties of the level that is played has.
  GameLevel level;

  set mazeId(int id) => <void>{maze.mazeId = id};

  int get mazeId => maze.mazeId;

  final AudioController audioController;
  final AppLifecycleStateNotifier appLifecycleStateNotifier;
  final PlayerProgress playerProgress;

  String _userString = "";

  static const int _deathPenaltyMillis = 5000;
  final Timer stopwatch = Timer(double.infinity);
  int get stopwatchMilliSeconds =>
      (stopwatch.current * 1000).toInt() +
      (level.isTutorial
          ? 0
          : min(level.maxAllowedDeaths - 1, numberOfDeathsNotifier.value) *
              _deathPenaltyMillis);

  bool stopwatchStarted = false;

  bool get isLive => !paused && isLoaded && isMounted;

  bool get openingScreenCleared =>
      !(!stopwatchStarted && overlays.isActive(GameScreen.startDialogKey));

  final ValueNotifier<int> numberOfDeathsNotifier = ValueNotifier<int>(0);

  bool get isWonOrLost =>
      world.pellets.pelletsRemainingNotifier.value <= 0 ||
      numberOfDeathsNotifier.value >= level.maxAllowedDeaths;

  final Random random = Random();

  late int playbackModeCounter;
  bool playbackMode = false;

  // ignore: dead_code
  static const bool recordMode = false && kDebugMode;
  List<List<double>> recordedMovesLive = <List<double>>[];

  void recordAngle(double angle) {
    if (recordMode && !playbackMode) {
      recordedMovesLive
          .add(<double>[(stopwatchMilliSeconds).toDouble(), angle]);
      if (recordedMovesLive.length % 100 == 0) {
        debug(recordedMovesLive);
      }
    }
  }

  void playbackAngles() {
    if (playbackMode && isLive && _framesRendered > 30) {
      // && isLive && overlays.isActive(GameScreen.startDialogKey)
      if (playbackModeCounter == -1) {
        playbackModeCounter++;
        startRegularItems();
      }
      while (!world.doingLevelResetFlourish &&
          playbackModeCounter < storedMoves.length &&
          stopwatchMilliSeconds > storedMoves[playbackModeCounter][0]) {
        world.setMazeAngle(storedMoves[playbackModeCounter][1]);
        playbackModeCounter++;
      }
      if (!world.doingLevelResetFlourish && stopwatchMilliSeconds > 20000) {
        reset(); //if stuck, reset
      }
    }
  }

  @override
  Color backgroundColor() => Palette.background.color;

  Map<String, dynamic> _getCurrentGameState() {
    final Map<String, dynamic> gameStateTmp = <String, dynamic>{};
    gameStateTmp["userString"] = _userString;
    gameStateTmp["levelNum"] = level.number;
    gameStateTmp["levelCompleteTime"] = stopwatchMilliSeconds;
    gameStateTmp["dateTime"] = DateTime.now().millisecondsSinceEpoch;
    gameStateTmp["mazeId"] = maze.mazeId;
    return gameStateTmp;
  }

  void pauseGame() {
    pause(); //timeScale = 0;
    pauseEngine();
    //stopwatch.pause(); //shouldn't be necessary given timeScale = 0
  }

  void resumeGame() {
    resume(); //timeScale = 1.0;
    resumeEngine();
  }

  bool _regularItemsStarted = false;
  void startRegularItems() {
    if (!_regularItemsStarted) {
      _regularItemsStarted = true;
      stopwatchStarted = true; //once per reset
      stopwatch.resume();
      world.ghosts
        ..addSpawner()
        ..sirenVolumeUpdaterTimer();
    }
  }

  void stopRegularItems() {
    _regularItemsStarted = false;
    stopwatch.pause();
    world.ghosts
      ..removeSpawner()
      ..cancelSirenVolumeUpdaterTimer();
  }

  void _lifecycleChangeListener() {
    appLifecycleStateNotifier.addListener(() {
      if (appLifecycleStateNotifier.value == AppLifecycleState.hidden) {
        pauseGame();
      }
    });
  }

  void _winOrLoseGameListener() {
    assert(!stopwatchStarted); //so no instant trigger of listeners
    numberOfDeathsNotifier.addListener(() {
      if (numberOfDeathsNotifier.value >= level.maxAllowedDeaths &&
          stopwatchStarted &&
          !playbackMode) {
        assert(isWonOrLost);
        stopRegularItems();
        _handleLoseGame();
      }
    });
    world.pellets.pelletsRemainingNotifier.addListener(() {
      if (world.pellets.pelletsRemainingNotifier.value == 0 &&
          stopwatchStarted &&
          !playbackMode) {
        assert(isWonOrLost);
        stopRegularItems();
        _handleWinGame();
      }
    });
  }

  static const int _minRecordableWinTimeMillis = 10 * 1000;
  void _handleWinGame() {
    assert(isWonOrLost);
    assert(!stopwatch.isRunning());
    assert(stopwatchStarted);
    if (world.pellets.pelletsRemainingNotifier.value == 0) {
      world.resetAfterGameWin();
      if (stopwatchMilliSeconds > _minRecordableWinTimeMillis &&
          !level.isTutorial) {
        fBase.firebasePushSingleScore(_userString, _getCurrentGameState());
      }
      playerProgress.saveLevelComplete(_getCurrentGameState());
      cleanDialogs();
      overlays.add(GameScreen.wonDialogKey);
    }
  }

  void _handleLoseGame() {
    assert(isWonOrLost);
    assert(stopwatchStarted);
    audioController.stopAllSfx();
    cleanDialogs();
    overlays.add(GameScreen.loseDialogKey);
  }

  void cleanDialogs() {
    overlays
      ..remove(GameScreen.startDialogKey)
      ..remove(GameScreen.loseDialogKey)
      ..remove(GameScreen.wonDialogKey)
      ..remove(GameScreen.tutorialDialogKey)
      ..remove(GameScreen.resetDialogKey);
  }

  void toggleOverlay(String overlayKey) {
    if (overlays.activeOverlays.contains(overlayKey)) {
      overlays.remove(overlayKey);
    } else {
      cleanDialogs();
      overlays.add(overlayKey);
    }
  }

  @override
  Future<void> onGameResize(Vector2 size) async {
    camera.viewport =
        FixedResolutionViewport(resolution: _sanitizeScreenSize(size));
    super.onGameResize(size);
  }

  void reset({bool firstRun = false, bool showStartDialog = false}) {
    playbackModeCounter = -1;
    playbackMode = !recordMode && level.number == Levels.playbackModeLevel;
    recordedMovesLive.clear();
    pauseEngineIfNoActivity();
    _userString = _getRandomString(random, 15);
    cleanDialogs();
    if (showStartDialog) {
      playbackMode
          ? overlays.add(GameScreen.beginDialogKey)
          : overlays.add(GameScreen.startDialogKey);
    }
    stopRegularItems(); //duplicates other items, belt and braces only
    stopwatch
      ..pause()
      ..reset();
    stopwatchStarted = false;
    if (!firstRun) {
      assert(world.isLoaded);
      world.reset();
    }
    collisionDetection.broadphase.tree.optimize();
  }

  void resetAndStart() {
    reset();
    start();
  }

  void start() {
    //resumeEngine();
    pauseEngineIfNoActivity();
    world.start();
  }

  int _framesRendered = 0;

  void pauseEngineIfNoActivity() {
    resumeEngine(); //for any catch up animation, if not already resumed
    _framesRendered = 0;
    async.Timer.periodic(const Duration(milliseconds: 10), (async.Timer timer) {
      if (paused) {
        //already paused, no further action required, just cancel timer
        timer.cancel();
      } else if (playbackMode) {
        //want to continue playback in playbackMode
        timer.cancel();
      } else if (stopwatch.isRunning()) {
        //some game activity has happened, no need to pause, just cancel timer
        timer.cancel();
      } else if (!world.isMounted || !world.ghosts.ghostsLoaded) {
        //core components haven't loaded yet, so wait before start frame count
        _framesRendered = 0;
      } else if (_framesRendered <= 5) {
        //core components loaded, but not yet had 5 good safety frame
      } else {
        //everything loaded and rendered, and still no game activity
        pauseEngine();
        timer.cancel();
      }
    });
  }

  void _bugFixes() {
    setStatusBarColor(Palette.background.color);
  }

  /// In the [onLoad] method you load different type of assets and set things
  /// that only needs to be set once when the level starts up.
  @override
  Future<void> onLoad() async {
    super.onLoad();
    _bugFixes();
    initializeCollisionDetection(
      mapDimensions: Rect.fromLTWH(-maze.mazeWidth / 2, -maze.mazeHeight / 2,
          maze.mazeWidth, maze.mazeHeight),
    ); //assume maze size won't change
    reset(firstRun: true, showStartDialog: true);
    _winOrLoseGameListener(); //isn't disposed so run once, not on start()
    _lifecycleChangeListener(); //isn't disposed so run once, not on start()
  }

  @override
  void update(double dt) {
    stopwatch.update(dt * timeScale); //stops stopwatch when timeScale = 0
    _framesRendered++;
    playbackAngles();
    super.update(dt);
  }

  @override
  Future<void> onRemove() async {
    cleanDialogs();
    audioController.stopAllSfx();
    super.onRemove();
  }
}

Vector2 _sanitizeScreenSize(Vector2 size) {
  if (size.x > size.y) {
    return Vector2(kVirtualGameSize * size.x / size.y, kVirtualGameSize);
  } else {
    return Vector2(kVirtualGameSize, kVirtualGameSize * size.y / size.x);
  }
}

const String _chars =
    'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

String _getRandomString(Random random, int length) =>
    String.fromCharCodes(Iterable<int>.generate(
        length, (_) => _chars.codeUnitAt(random.nextInt(_chars.length))));
