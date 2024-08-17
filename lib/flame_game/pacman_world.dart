import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../audio/sounds.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../utils/helper.dart';
import 'components/ghost_layer.dart';
import 'components/pacman.dart';
import 'components/pacman_layer.dart';
import 'components/pellet_layer.dart';
import 'components/tutorial_layer.dart';
import 'components/wall_blocking_layer.dart';
import 'components/wall_layer.dart';
import 'components/wrapper_no_events.dart';
import 'effects/rotate_by_effect.dart';
import 'pacman_game.dart';

/// The world is where you place all the components that should live inside of
/// the game, like the player, enemies, obstacles and points for example.
/// The world can be much bigger than what the camera is currently looking at,
/// but in this game all components that go outside of the size of the viewport
/// are removed, since the player can't interact with those anymore.
///
/// The [PacmanWorld] has two mixins added to it:
///  - The [DragCallbacks] that makes it possible to react to taps and drags
///  (or mouse clicks) on the world.
///  - The [HasGameReference] that gives the world access to a variable called
///  `game`, which is a reference to the game class that the world is attached
///  to.

final bool _iOSWeb = defaultTargetPlatform == TargetPlatform.iOS && kIsWeb;

class PacmanWorld extends Forge2DWorld
    with
        //TapCallbacks,
        HasGameReference<PacmanGame>,
        //PointerMoveCallbacks,
        DragCallbacks {
  PacmanWorld({
    required this.level,
    required this.playerProgress,
    Random? random,
  });

  /// The properties of the current level.
  final GameLevel level;

  /// Used to see what the current progress of the player is and to update the
  /// progress if a level is finished.
  final PlayerProgress playerProgress;

  final noEventsWrapper = WrapperNoEvents();
  final pacmans = Pacmans();
  final ghosts = Ghosts();
  final pellets = PelletWrapper();
  final _walls = WallWrapper();
  final _tutorial = TutorialWrapper();
  final _blockingWalls = WallBlockingWrapper();
  final List<WrapperNoEvents> wrappers = [];

  bool get gameWonOrLost =>
      pellets.pelletsRemainingNotifier.value <= 0 ||
      pacmans.numberOfDeathsNotifier.value >= level.maxAllowedDeaths;

  final Map<int, double?> _fingersLastDragAngle = {};

  bool doingLevelResetFlourish = false;
  bool _cameraRotatableOnPacmanDeathFlourish = true;

  /// The gravity is defined in virtual pixels per second squared.
  /// These pixels are in relation to how big the [FixedResolutionViewport] is.

  void play(SfxType type) {
    const soundOn = true; //!(windows && !kIsWeb);
    if (soundOn) {
      game.audioController.playSfx(type);
    }
  }

  void resetAfterGameWin() {
    game.audioController.stopSfx(SfxType.ghostsScared);
    play(SfxType.endMusic);
    ghosts.resetAfterGameWin();
  }

  static const bool _slideCharactersAfterPacmanDeath = true;

  void resetAfterPacmanDeath(Pacman dyingPacman) {
    resetSlideAfterPacmanDeath(dyingPacman);
  }

  void resetSlideAfterPacmanDeath(Pacman dyingPacman) {
    //reset ghost scared status. Shouldn't be relevant as just died
    game.audioController.stopSfx(SfxType.ghostsScared);
    if (!gameWonOrLost) {
      if (_slideCharactersAfterPacmanDeath) {
        _cameraRotatableOnPacmanDeathFlourish = false;
        dyingPacman.resetSlideAfterDeath();
        ghosts.resetSlideAfterPacmanDeath();
        game.camera.viewfinder.add(RotateByAngleEffect(
            smallAngle(-game.camera.viewfinder.angle),
            onComplete: _resetInstantAfterPacmanDeath));
      } else {
        _resetInstantAfterPacmanDeath();
      }
    } else {
      doingLevelResetFlourish = false;
    }
  }

  void _cameraAndTimersReset() {
    //stop any rotation effect added to camera
    //note, still leaves flourish variable hot, so fix below
    game.camera.viewfinder.removeWhere((item) => item is Effect);
    _setMazeAngle(0);
    _cameraRotatableOnPacmanDeathFlourish = true;
    doingLevelResetFlourish = false;
  }

  void _resetInstantAfterPacmanDeath() {
    pacmans.resetInstantAfterPacmanDeath();
    ghosts.resetInstantAfterPacmanDeath();
    _cameraAndTimersReset();
  }

  void reset({firstRun = false}) {
    _cameraAndTimersReset();

    if (!firstRun) {
      for (WrapperNoEvents wrapper in wrappers) {
        assert(wrapper.isLoaded);
        wrapper.reset();
      }
    }
  }

  void start() {
    play(SfxType.startMusic);
    for (WrapperNoEvents wrapper in wrappers) {
      wrapper.start();
    }
  }

  @override
  Future<void> onLoad() async {
    add(noEventsWrapper);
    wrappers
        .addAll([pacmans, ghosts, pellets, _walls, _tutorial, _blockingWalls]);
    for (WrapperNoEvents wrapper in wrappers) {
      noEventsWrapper.add(wrapper);
    }
    reset(firstRun: true);
    super.onLoad();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_iOSWeb) {
      _fingersLastDragAngle[event.pointerId] = null;
    } else {
      _fingersLastDragAngle[event.pointerId] = atan2(
          event.canvasPosition.x - game.canvasSize.x / 2,
          event.canvasPosition.y - game.canvasSize.y / 2);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    game.resume();
    double eventVectorLengthProportion =
        (event.canvasStartPosition - game.canvasSize / 2).length /
            (min(game.canvasSize.x, game.canvasSize.y) / 2);
    double fingerCurrentDragAngle = atan2(
        event.canvasStartPosition.x - game.canvasSize.x / 2,
        event.canvasStartPosition.y - game.canvasSize.y / 2);
    if (_fingersLastDragAngle.containsKey(event.pointerId)) {
      if (_fingersLastDragAngle[event.pointerId] != null) {
        double angleDelta = smallAngle(
            fingerCurrentDragAngle - _fingersLastDragAngle[event.pointerId]!);
        double spinMultiplier = 4 * min(1, eventVectorLengthProportion / 0.75);

        _tutorial.hide();
        _moveMazeAngleByDelta(angleDelta * spinMultiplier);
      }
      _fingersLastDragAngle[event.pointerId] = fingerCurrentDragAngle;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (_fingersLastDragAngle.containsKey(event.pointerId)) {
      _fingersLastDragAngle.remove(event.pointerId);
    }
  }

  void _moveMazeAngleByDelta(double angleDelta) {
    if (_cameraRotatableOnPacmanDeathFlourish && game.isGameLive) {
      _setMazeAngle(game.camera.viewfinder.angle + angleDelta);

      if (!doingLevelResetFlourish) {
        game.stopwatch.resume();
        ghosts.addSpawner();
        ghosts.sirenVolumeUpdatedTimer();
      }
    }
  }

  void _setMazeAngle(double angle) {
    gravity = Vector2(cos(angle + 2 * pi / 4), sin(angle + 2 * pi / 4)) *
        50 *
        (30 / flameGameZoom);
    game.camera.viewfinder.angle = angle;
  }
}
