import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../audio/audio_controller.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';

import 'endless_world.dart';
import 'constants.dart';
import 'helper.dart';
import 'dart:core';
import 'dart:async' as async;
import 'dart:convert';
import 'package:wakelock_plus/wakelock_plus.dart';
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
///  [EndlessWorld].
///
/// Note that both of the last are passed in to the super constructor, they
/// could also be set inside of `onLoad` for example.

class EndlessRunner extends Forge2DGame<EndlessWorld>
    with HasCollisionDetection {
  EndlessRunner({
    required this.level,
    required PlayerProgress playerProgress,
    required this.audioController,
  }) : super(
          world: EndlessWorld(level: level, playerProgress: playerProgress),
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

  final List<double> leaderboardWinTimes = [];

  @override
  Color backgroundColor() => palette.flameGameBackground.color;

  bool isGameLive() {
    return gameRunning && !paused && isLoaded && isMounted;
  }

  void deadMansSwitch() async {
    //Works as separate thread to stop all audio when game stops
    async.Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isGameLive()) {
        audioController.stopAllSfx();
        timer.cancel();
      }
    });
  }

  String getEncodeCurrentGameState() {
    Map<String, dynamic> gameTmp = {};
    gameTmp = {};
    gameTmp["userString"] = userString;
    gameTmp["levelCompleteTime"] = world.getLevelCompleteTimeSeconds();
    return json.encode(gameTmp);
  }

  List<double> leaderboardPercentiles() {
    List<double> percentilesList = [];

    List<double> newList = List<double>.from(leaderboardWinTimes);
    newList.sort();

    for (int i = 0; i < 101; i++) {
      percentilesList.add(newList[(i / 100 * (newList.length - 1)).floor()]);
    }
    return percentilesList;
  }

  List<double> summariseLeaderboard(List<double> startList) {
    List<double> percentilesList = [];

    List<double> newList = List<double>.from(startList);

    if (newList.isNotEmpty) {
      newList.sort();

      for (int i = 0; i < 101; i++) {
        percentilesList.add(newList[(i / 100 * (newList.length - 1)).floor()]);
      }
    }
    return percentilesList;
  }

  String encodeSummarisedLeaderboard(percentilesList) {
    Map<String, dynamic> gameTmp = {};
    gameTmp = {};
    gameTmp["effectiveDate"] = DateTime.now().millisecondsSinceEpoch;
    gameTmp["percentilesList"] = percentilesList;
    String result = json.encode(gameTmp);
    //p(["encoded percentiles", result]);
    return result;
  }

  /*
  Future<void> downloadLeaderboardFull() async {
    if (leaderboardWinTimes.isEmpty) {
      //so don't re-download
      List firebaseDownloadCache = await save.firebasePullFull();
      for (int i = 0; i < firebaseDownloadCache.length; i++) {
        leaderboardWinTimes.add(firebaseDownloadCache[i]["levelCompleteTime"]);
      }
    }
  }
   */

  Future<List<double>> downloadLeaderboardFull() async {
    List<double> tmpList = [];
    List firebaseDownloadCache = await save.firebasePullFullLeaderboard();
    for (int i = 0; i < firebaseDownloadCache.length; i++) {
      tmpList.add(firebaseDownloadCache[i]["levelCompleteTime"]);
    }
    return tmpList;
  }

  Future<Map<String, dynamic>> downLeaderboardSummary() async {
    String firebaseDownloadCacheEncoded =
        await save.firebasePullSummaryLeaderboard();
    Map<String, dynamic> gameTmp = {};
    gameTmp = json.decode(firebaseDownloadCacheEncoded);
    return gameTmp;
  }

  void cacheLeaderboard() async {
    Map<String, dynamic> leaderboardSummary = {};

    if (leaderboardWinTimes.isEmpty) {
      //so don't re-download
      try {
        leaderboardSummary = await downLeaderboardSummary();
      } catch (e) {
        //likely firebase database blank, i.e. first run
        p(e);
      }

      if (leaderboardSummary.isEmpty ||
          leaderboardSummary["percentilesList"].isEmpty ||
          leaderboardSummary["effectiveDate"] <
              DateTime.now().millisecondsSinceEpoch -
                  1000 * 60 * 60 -
                  1000 * 60 * 10 * world.random.nextDouble()) {
        //random 10 minutes to avoid multiple hits at the same time
        p("full refresh required");
        await save.firebasePushSummaryLeaderboard(encodeSummarisedLeaderboard(
            summariseLeaderboard(await downloadLeaderboardFull())));
        p("pushed new summary");
        leaderboardSummary = await downLeaderboardSummary();
        p("refreshed summary download");
      }

      leaderboardWinTimes.clear();
      for (int i = 0; i < leaderboardSummary["percentilesList"].length; i++) {
        leaderboardWinTimes.add(leaderboardSummary["percentilesList"][i]);
      }
      p("summary saved");
    }
  }

  @override
  Future<void> onGameResize(size) async {
    Vector2 targetViewPortSize = sanitizeScreenSize(size);
    camera.viewport = FixedResolutionViewport(
        resolution: Vector2(targetViewPortSize.x, targetViewPortSize.y));
    super.onGameResize(size);
  }

  /// In the [onLoad] method you load different type of assets and set things
  /// that only needs to be set once when the level starts up.
  @override
  Future<void> onLoad() async {
    WakelockPlus.toggle(enable: true);
    gameRunning = true;
    userString = getRandomString(world.random, 15);
    deadMansSwitch();
  }
}
