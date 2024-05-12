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
import 'components/maze_walls.dart';
import '../../audio/sounds.dart';
import 'dart:core';
import 'dart:convert';

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
              width: dx, height: dy), //2800, 1700 //CameraComponent(),//
          zoom: flameGameZoom,
        );

  /// What the properties of the level that is played has.
  final GameLevel level;

  /// A helper for playing sound effects and background audio.
  final AudioController audioController;

  double dxLast = 0;
  double dyLast = 0;

  String userString = "";

  final scoreComponent = TextComponent(
    text: "Lives: 3",
    position: Vector2(dx - 30 - 300, 30),
    textRenderer: textRenderer,
  );




  String getEncodeCurrentGameState() {
    Map<String, dynamic> gameTmp = {};
    gameTmp = {};
    gameTmp["userString"] = userString;
    gameTmp["levelCompleteTime"] = world.getLevelTimeSeconds();
    return json.encode(gameTmp);
  }

  void downloadScoreboard() async {
    List firebasePull = await save.firebasePull();
    for (int i = 0; i< firebasePull.length; i++) {
      scoreboardItemsDoubles.add(firebasePull[i]["levelCompleteTime"]);
    }
  }


  /// In the [onLoad] method you load different type of assets and set things
  /// that only needs to be set once when the level starts up.
  @override
  Future<void> onLoad() async {
    userString = getRandomString(world.random, 15);
    downloadScoreboard();
    world.play(SfxType.startMusic);
    world.addAll(createBoundaries(camera));
    //camera.viewfinder.angle = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!actuallyMoveSpritesToScreenPos) {
      camera.viewfinder.angle = -world.worldAngle;
    }
    scoreComponent.text =
        'Lives: ${3 - world.scoreNotifier.value} \n\nTime: ${world.getLevelTimeSeconds().toStringAsFixed(1)}';

    if (dxLast != dx || dyLast != dy) {
      camera.viewport = FixedResolutionViewport(resolution: Vector2(dx, dy));
      camera.viewport.add(scoreComponent);
      scoreComponent.position = Vector2(dx - 30 - 350, 30);
      dxLast = dx;
      dyLast = dy;
    }
  }
}
