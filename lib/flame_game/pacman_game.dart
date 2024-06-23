import 'dart:convert';
import 'dart:core';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

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
    required this.palette,
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
  final Palette palette;

  String userString = "";
  final stopwatch = Stopwatch();
  double get stopwatchSeconds => stopwatch.elapsed.inMilliseconds / 1000;
  bool get isGameLive => !paused && isLoaded && isMounted;

  @override
  Color backgroundColor() => palette.flameGameBackground.color;

  String getEncodeCurrentGameState() {
    Map<String, dynamic> gameTmp = {};
    gameTmp = {};
    gameTmp["userString"] = userString;
    gameTmp["levelCompleteTime"] = stopwatchSeconds;
    return json.encode(gameTmp);
  }

  void winOrLoseGameListener() {
    assert(world.pelletsRemainingNotifier.value > 0);
    world.numberOfDeathsNotifier.addListener(() {
      if (world.numberOfDeathsNotifier.value >= level.maxAllowedDeaths) {
        handleLoseGame();
      }
    });
    world.pelletsRemainingNotifier.addListener(() {
      if (world.pelletsRemainingNotifier.value == 0) {
        handleWinGame();
      }
      if (world.pelletsRemainingNotifier.value == 5) {
        save.cacheLeaderboardNow(); //close to the end but not at the end
      }
    });
  }

  void handleWinGame() {
    if (isGameLive) {
      if (world.pelletsRemainingNotifier.value == 0) {
        world.winGameWorldTidy();
        stopwatch.stop();
        if (stopwatchSeconds > 10) {
          save.firebasePushSingleScore(userString, getEncodeCurrentGameState());
        }
        cleanOverlays();
        overlays.add(GameScreen.wonDialogKey);
      }
    }
  }

  void handleLoseGame() {
    pauseEngine();
    audioController.stopAllSfx();
    cleanOverlays();
    overlays.add(GameScreen.loseDialogKey);
  }

  void cleanOverlays() {
    overlays.remove(GameScreen.backButtonKey);
    overlays.remove(GameScreen.statusOverlayKey);
  }

  @override
  Future<void> onGameResize(Vector2 size) async {
    Vector2 targetViewPortSize = _sanitizeScreenSize(size);
    camera.viewport = FixedResolutionViewport(
        resolution: Vector2(targetViewPortSize.x, targetViewPortSize.y));
    super.onGameResize(size);
  }

  /// In the [onLoad] method you load different type of assets and set things
  /// that only needs to be set once when the level starts up.
  @override
  Future<void> onLoad() async {
    super.onLoad();
    userString = _getRandomString(world.random, 15);
    overlays.add(GameScreen.backButtonKey);
    overlays.add(GameScreen.statusOverlayKey);
    setStatusBarColor(palette.flameGameBackground.color);
    fixTitle(Palette.black);
    Future.delayed(const Duration(seconds: 1), () {
      fixTitle(Palette.black);
    });
  }

  @override
  Future<void> onRemove() async {
    cleanOverlays();
    setStatusBarColor(palette.backgroundMain.color);
    fixTitle(Palette.lightBluePMR);
    audioController.stopAllSfx();
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
