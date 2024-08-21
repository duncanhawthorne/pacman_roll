import 'dart:async' as async;
import 'dart:core';
import 'dart:math';
import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../app_lifecycle/app_lifecycle.dart';
import '../audio/audio_controller.dart';
import '../firebase/firebase_saves.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../style/palette.dart';
import '../utils/helper.dart';
import 'game_screen.dart';
import 'maze.dart';
import 'pacman_world.dart';

/// This is the base of the game which is added to the [GameWidget].
///
/// This class defines a few different properties for the game:
///  - That it should have a [FixedResolutionViewport] containing
///  a square of size [kSquareNotionalSize]
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
const flameGameZoom = 30.0;
const _visualZoomMultiplier = 0.92;
const double kSquareNotionalSize = 1700; //determines speed of game

class PacmanGame extends Forge2DGame<PacmanWorld>
    with HasCollisionDetection, HasTimeScale {
  PacmanGame({
    required this.level,
    required mazeId,
    required PlayerProgress playerProgress,
    required this.audioController,
    required this.appLifecycleStateNotifier,
  }) : super(
          world: PacmanWorld(level: level, playerProgress: playerProgress),
          camera: CameraComponent.withFixedResolution(
              width: kSquareNotionalSize,
              height: kSquareNotionalSize), //2800, 1700 //CameraComponent(),//
          zoom: flameGameZoom * _visualZoomMultiplier,
        ) {
    _setMazeId(mazeId);
  }

  /// What the properties of the level that is played has.
  final GameLevel level;

  final AudioController audioController;
  final AppLifecycleStateNotifier appLifecycleStateNotifier;

  void _setMazeId(id) {
    maze.mazeId = id;
  }

  String _userString = "";

  Timer stopwatch = Timer(double.infinity);
  int get stopwatchMilliSeconds =>
      (stopwatch.current * 1000).toInt() +
      world.pacmans.numberOfDeathsNotifier.value * 5000;
  bool get levelStarted => stopwatchMilliSeconds > 0;

  bool get isGameLive =>
      !paused &&
      isLoaded &&
      isMounted &&
      !(overlays.isActive(GameScreen.startDialogKey) && !levelStarted);

  final Random random = Random();

  @override
  Color backgroundColor() => Palette.flameGameBackground.color;

  Map<String, dynamic> _getCurrentGameState() {
    Map<String, dynamic> gameTmp = {};
    gameTmp = {};
    gameTmp["userString"] = _userString;
    gameTmp["levelNum"] = level.number;
    gameTmp["levelCompleteTime"] = stopwatchMilliSeconds;
    gameTmp["dateTime"] = DateTime.now().millisecondsSinceEpoch;
    gameTmp["mazeId"] = maze.mazeId;
    return gameTmp;
  }

  void resume() {
    timeScale = 1.0;
    resumeEngine();
  }

  void _lifecycleChangeListener() {
    appLifecycleStateNotifier.addListener(() {
      if (appLifecycleStateNotifier.value == AppLifecycleState.hidden) {
        timeScale = 0;
        pauseEngine();
        stopwatch.pause(); //shouldn't be necessary given timeScale = 0
      }
    });
  }

  void _winOrLoseGameListener() {
    assert(world.pellets.pelletsRemainingNotifier.value > 0 || !levelStarted);
    world.pacmans.numberOfDeathsNotifier.addListener(() {
      if (world.pacmans.numberOfDeathsNotifier.value >=
              level.maxAllowedDeaths &&
          levelStarted) {
        _handleLoseGame();
      }
    });
    world.pellets.pelletsRemainingNotifier.addListener(() {
      if (world.pellets.pelletsRemainingNotifier.value == 0 && levelStarted) {
        _handleWinGame();
      }
    });
  }

  void _handleWinGame() {
    if (isGameLive) {
      if (world.pellets.pelletsRemainingNotifier.value == 0) {
        world.resetAfterGameWin();
        stopwatch.pause();
        if (stopwatchMilliSeconds > 10 * 1000) {
          save.firebasePushSingleScore(_userString, _getCurrentGameState());
        }
        world.playerProgress
            .setLevelFinished(level.number, stopwatchMilliSeconds);
        _cleanOverlaysAndDialogs();
        overlays.add(GameScreen.wonDialogKey);
      }
    }
  }

  void _handleLoseGame() {
    audioController.stopAllSfx();
    _cleanOverlaysAndDialogs();
    overlays.add(GameScreen.loseDialogKey);
  }

  void _addOverlays() {
    overlays.add(GameScreen.topLeftOverlayKey);
    overlays.add(GameScreen.topRightOverlayKey);
  }

  void _cleanOverlaysAndDialogs() {
    overlays.remove(GameScreen.topLeftOverlayKey);
    overlays.remove(GameScreen.topRightOverlayKey);
    overlays.remove(GameScreen.startDialogKey);
    overlays.remove(GameScreen.loseDialogKey);
    overlays.remove(GameScreen.wonDialogKey);
  }

  @override
  Future<void> onGameResize(Vector2 size) async {
    camera.viewport =
        FixedResolutionViewport(resolution: _sanitizeScreenSize(size));
    super.onGameResize(size);
  }

  void reset({firstRun = false}) {
    _userString = _getRandomString(random, 15);
    _cleanOverlaysAndDialogs();
    _addOverlays();
    stopwatch.pause();
    stopwatch.reset();
    if (!firstRun) {
      assert(world.isLoaded);
      world.reset();
    }
  }

  void resetAndStart() {
    reset();
    start();
  }

  void start() {
    resumeEngine();
    world.start();
  }

  void showMainMenu() {
    overlays.add(GameScreen.startDialogKey);

    async.Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (!isGameLive) {
        if (world.isMounted) {
          //some rendering has happened
          pauseEngine();
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _bugFixes() {
    setStatusBarColor(Palette.flameGameBackground.color);
    fixTitle(Palette.black);
    Future.delayed(const Duration(seconds: 1), () {
      fixTitle(Palette.black);
    });
  }

  /// In the [onLoad] method you load different type of assets and set things
  /// that only needs to be set once when the level starts up.
  @override
  Future<void> onLoad() async {
    super.onLoad();
    _bugFixes();
    reset(firstRun: true);
    showMainMenu();
    _winOrLoseGameListener(); //isn't disposed so run once, not on start()
    _lifecycleChangeListener(); //isn't disposed so run once, not on start()
  }

  @override
  void update(double dt) {
    stopwatch.update(dt);
    super.update(dt);
  }

  void _end() {
    audioController.stopAllSfx();
  }

  @override
  Future<void> onRemove() async {
    _cleanOverlaysAndDialogs();
    setStatusBarColor(Palette.mainBackground.color);
    fixTitle(Palette.lightBluePMR);
    _end();
    super.onRemove();
  }
}

Vector2 _sanitizeScreenSize(Vector2 size) {
  if (size.x > size.y) {
    return Vector2(kSquareNotionalSize * size.x / size.y, kSquareNotionalSize);
  } else {
    return Vector2(kSquareNotionalSize, kSquareNotionalSize * size.y / size.x);
  }
}

const String _chars =
    'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

String _getRandomString(random, int length) =>
    String.fromCharCodes(Iterable.generate(
        length, (_) => _chars.codeUnitAt(random.nextInt(_chars.length))));
