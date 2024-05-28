import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../audio/audio_controller.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';

import 'game_screen.dart';
import 'pacman_world.dart';
import 'constants.dart';
import 'helper.dart';
import 'dart:core';
import 'dart:convert';
import 'package:flame/palette.dart';

/// This is the base of the game which is added to the [GameWidget].
///
/// This class defines a few different properties for the game:
///  - That it should run collision detection, this is done through the
///  [HasCollisionDetection] mixin.
///  - That it should have a [FixedResolutionViewport] with a size of 1600x720,
///  this means that even if you resize the window, the game itself will keep
///  the defined virtual resolution.
///  - That the default world that the camera is looking at should be the
///  [PacmanWorld].
///
/// Note that both of the last are passed in to the super constructor, they
/// could also be set inside of `onLoad` for example.

class PacmanGame extends Forge2DGame<PacmanWorld> with HasCollisionDetection {
  PacmanGame({
    required this.level,
    required PlayerProgress playerProgress,
    required this.audioController,
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

  String userString = "";
  final stopwatch = Stopwatch();

  @override
  Color backgroundColor() => palette.flameGameBackground.color;

  bool isGameLive() {
    return !paused && isLoaded && isMounted; //gameRunningFailsafeIndicator &&
  }

  String getEncodeCurrentGameState() {
    Map<String, dynamic> gameTmp = {};
    gameTmp = {};
    gameTmp["userString"] = userString;
    gameTmp["levelCompleteTime"] = stopwatchSeconds();
    return json.encode(gameTmp);
  }

  double stopwatchSeconds() {
    return stopwatch.elapsed.inMilliseconds / 1000;
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
    if (isGameLive()) {
      if (world.pelletsRemainingNotifier.value == 0) {
        world.winGameWorldTidy();
        stopwatch.stop();
        if (stopwatchSeconds() > 10) {
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
    overlays.remove(GameScreen.statusOverlay);
  }

  @override
  Future<void> onGameResize(size) async {
    Vector2 targetViewPortSize = getSanitizedScreenSize(size);
    camera.viewport = FixedResolutionViewport(
        resolution: Vector2(targetViewPortSize.x, targetViewPortSize.y));
    super.onGameResize(size);
  }

  /// In the [onLoad] method you load different type of assets and set things
  /// that only needs to be set once when the level starts up.
  @override
  Future<void> onLoad() async {
    super.onLoad();
    //gameRunningFailsafeIndicator = true;
    userString = getRandomString(world.random, 15);
    overlays.add(GameScreen.backButtonKey);
    overlays.add(GameScreen.statusOverlay);
    setStatusBarColor(palette.flameGameBackground.color);
    fixTitle(black);
    Future.delayed(const Duration(seconds: 1), () {
      fixTitle(black);
    });
    //WakelockPlus.toggle(enable: true);
  }

  @override
  Future<void> onRemove() async {
    //gameRunningFailsafeIndicator = false;
    cleanOverlays();
    setStatusBarColor(palette.backgroundMain.color);
    fixTitle(lightBluePMR);
    //WakelockPlus.toggle(enable: false);
    audioController.stopAllSfx();
    super.onRemove();
  }
}
