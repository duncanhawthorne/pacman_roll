import 'dart:core';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/animation.dart';

import '../audio/audio_controller.dart';
import '../firebase/firebase_saves.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../style/palette.dart';
import '../utils/helper.dart';
import 'game_screen.dart';
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

const flameGameZoom = 30.0; //determines speed of game
const double kSquareNotionalSize = 1700; //determines speed of game

class PacmanGame extends Forge2DGame<PacmanWorld> with HasCollisionDetection {
  PacmanGame({
    required this.level,
    required PlayerProgress playerProgress,
    required this.audioController,
    //required this.palette,
  }) : super(
          world: PacmanWorld(level: level, playerProgress: playerProgress),
          camera: CameraComponent.withFixedResolution(
              width: kSquareNotionalSize,
              height: kSquareNotionalSize), //2800, 1700 //CameraComponent(),//
          zoom: flameGameZoom,
        );

  /// What the properties of the level that is played has.
  final GameLevel level;

  /// A helper for playing sound effects and background audio.
  final AudioController audioController;

  //final Palette palette;

  String userString = "";
  final stopwatch = Stopwatch();

  int get stopwatchMilliSeconds =>
      stopwatch.elapsed.inMilliseconds +
      world.numberOfDeathsNotifier.value * 5000;

  bool get levelStarted => stopwatchMilliSeconds > 0;
  bool mazeEverRotated = false;

  bool get isGameLive =>
      !paused &&
      isLoaded &&
      isMounted &&
      !(overlays.isActive(GameScreen.startDialogKey) && !levelStarted);

  @override
  Color backgroundColor() => Palette.flameGameBackground.color;

  Map<String, dynamic> getEncodeCurrentGameState() {
    Map<String, dynamic> gameTmp = {};
    gameTmp = {};
    gameTmp["userString"] = userString;
    gameTmp["levelNum"] = level.number;
    gameTmp["levelCompleteTime"] = stopwatchMilliSeconds;
    gameTmp["dateTime"] = world.now;
    return gameTmp;
  }

  void winOrLoseGameListener() {
    assert(world.pelletsRemainingNotifier.value > 0);
    world.numberOfDeathsNotifier.addListener(() {
      if (world.numberOfDeathsNotifier.value >= level.maxAllowedDeaths &&
          levelStarted) {
        handleLoseGame();
      }
    });
    world.pelletsRemainingNotifier.addListener(() {
      if (world.pelletsRemainingNotifier.value == 0 && levelStarted) {
        handleWinGame();
      }
    });
  }

  void handleWinGame() {
    if (isGameLive) {
      if (world.pelletsRemainingNotifier.value == 0) {
        world.winGameWorldTidy();
        stopwatch.stop();
        if (stopwatchMilliSeconds > 10 * 1000) {
          save.firebasePushSingleScore(userString, getEncodeCurrentGameState());
        }
        world.playerProgress
            .setLevelFinished(level.number, stopwatchMilliSeconds);
        cleanOverlaysAndDialogs();
        overlays.add(GameScreen.wonDialogKey);
      }
    }
  }

  void handleLoseGame() {
    //pauseEngine();
    audioController.stopAllSfx();
    cleanOverlaysAndDialogs();
    overlays.add(GameScreen.loseDialogKey);
  }

  void addOverlays() {
    overlays.add(GameScreen.topLeftOverlayKey);
    overlays.add(GameScreen.topRightOverlayKey);
  }

  void cleanOverlaysAndDialogs() {
    overlays.remove(GameScreen.topLeftOverlayKey);
    overlays.remove(GameScreen.topRightOverlayKey);
    overlays.remove(GameScreen.startDialogKey);
    overlays.remove(GameScreen.loseDialogKey);
    overlays.remove(GameScreen.wonDialogKey);
  }

  @override
  Future<void> onGameResize(Vector2 size) async {
    Vector2 targetViewPortSize = _sanitizeScreenSize(size);
    camera.viewport = FixedResolutionViewport(
        resolution: Vector2(targetViewPortSize.x, targetViewPortSize.y));
    super.onGameResize(size);
  }

  void reset() {
    userString = _getRandomString(world.random, 15);
    cleanOverlaysAndDialogs();
    addOverlays();
    stopwatch.stop();
    stopwatch.reset();
    world.reset();
  }

  void start() {
    resumeEngine();
    reset();
    world.start();
  }

  /// In the [onLoad] method you load different type of assets and set things
  /// that only needs to be set once when the level starts up.
  @override
  Future<void> onLoad() async {
    super.onLoad();
    reset();
    setStatusBarColor(Palette.flameGameBackground.color);
    fixTitle(Palette.black);
    Future.delayed(const Duration(seconds: 1), () {
      fixTitle(Palette.black);
    });
    if (overlayMainMenu) {
      overlays.add(GameScreen.startDialogKey);
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!isGameLive) {
          //i.e. dialog still showing
          pauseEngine();
          //camera.viewfinder.add(RotateEffect.by(2 * pi,
          //    EffectController(duration: 20000 / 1000, curve: Curves.linear)));
        }
      });
    }
  }

  void end() {
    audioController.stopAllSfx();
  }

  @override
  Future<void> onRemove() async {
    cleanOverlaysAndDialogs();
    setStatusBarColor(Palette.mainBackground.color);
    fixTitle(Palette.lightBluePMR);
    end();
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
