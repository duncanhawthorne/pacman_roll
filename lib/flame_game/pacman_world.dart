import 'dart:async';
import 'dart:math';

import 'package:flame_forge2d/flame_forge2d.dart';

import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
// ignore: implementation_imports
//import 'package:flame/src/events/messages/pointer_move_event.dart'
//    as flame_pointer_move_event;

import '../../audio/sounds.dart';
import 'pacman_game.dart';
import 'components/game_character.dart';
import 'components/maze_layout.dart';
import 'components/pacman.dart';
import 'components/ghost.dart';
import 'constants.dart';
import 'helper.dart';
import 'package:flutter/foundation.dart';
import 'dart:async' as async;

/// The world is where you place all the components that should live inside of
/// the game, like the player, enemies, obstacles and points for example.
/// The world can be much bigger than what the camera is currently looking at,
/// but in this game all components that go outside of the size of the viewport
/// are removed, since the player can't interact with those anymore.
///
/// The [PacmanWorld] has two mixins added to it:
///  - The [TapCallbacks] that makes it possible to react to taps (or mouse
///  clicks) on the world.
///  - The [HasGameReference] that gives the world access to a variable called
///  `game`, which is a reference to the game class that the world is attached
///  to.
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
  }) : random = random ?? Random();

  /// The properties of the current level.
  final GameLevel level;

  /// Used to see what the current progress of the player is and to update the
  /// progress if a level is finished.
  final PlayerProgress playerProgress;

  final numberOfDeathsNotifier = ValueNotifier(0);
  final pelletsRemainingNotifier = ValueNotifier(0);
  int allGhostScaredTimeLatest = 0;

  int now = DateTime.now().millisecondsSinceEpoch;
  //Vector2 get size => (parent as FlameGame).size;

  double _lastDragAngle = 10;
  double _gravityTargetAngle = 2 * pi / 4;

  final Random random;

  bool physicsOn = true;

  /// The gravity is defined in virtual pixels per second squared.
  /// These pixels are in relation to how big the [FixedResolutionViewport] is.

  List<Ghost> ghostPlayersList = [];
  List<Pacman> pacmanPlayersList = [];

  void play(SfxType type) {
    if (soundOn) {
      game.audioController.playSfx(type);
    }
  }

  bool gameWonOrLost() {
    return pelletsRemainingNotifier.value <= 0 ||
        numberOfDeathsNotifier.value >= level.maxAllowedDeaths;
  }

  void sirenVolumeUpdatedTimer() async {
    //NOTE disabled on iOS due to bug
    async.Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (game.isGameLive()) {
        game.audioController.setSirenVolume(getTargetSirenVolume(this));
      } else {
        game.audioController.setSirenVolume(0);
        timer.cancel();
      }
    });
  }

  void addGhost(int ghostSpriteChooserNumber) {
    Vector2 target = kGhostStartLocation +
        Vector2(
            singleSquareWidth() *
                (ghostSpriteChooserNumber <= 2
                    ? (ghostSpriteChooserNumber - 1)
                    : 0),
            0);
    Ghost ghost = Ghost(position: target);
    ghost.ghostSpriteChooserNumber = ghostSpriteChooserNumber;
    if (multipleSpawningGhosts && ghostPlayersList.isNotEmpty) {
      //new ghosts are also scared
      ghost.current =
          CharacterState.scared; //and then will get sequenced to correct state
    }
    add(ghost);
  }

  void multiGhostAdderTimer() {
    if (multipleSpawningGhosts) {
      async.Timer.periodic(const Duration(milliseconds: 5000), (timer) {
        if (game.isGameLive()) {
          if (!gameWonOrLost()) {
            addGhost(100);
          }
        } else {
          timer.cancel();
        }
      });
    }
  }

  void trimToThreeGhosts() {
    while (ghostPlayersList.length > 3) {
      assert(multipleSpawningGhosts);
      remove(ghostPlayersList[ghostPlayersList.length - 1]);
    }
  }

  void winGameWorldTidy() {
    Future.delayed(
        const Duration(milliseconds: kPacmanHalfEatingResetTimeMillis * 2),
            () {
          play(SfxType.endMusic);
        });
    trimToThreeGhosts();
    for (int i = 0; i < ghostPlayersList.length; i++) {
      ghostPlayersList[i].setPositionForGameEnd();
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    play(SfxType.startMusic);
    if (sirenEnabled) {
      play(SfxType.ghostsRoamingSiren);
      game.audioController.setSirenVolume(0);
      sirenVolumeUpdatedTimer();
    }

    add(Pacman(position: kPacmanStartLocation));
    for (int i = 0; i < 3; i++) {
      addGhost(i);
    }
    addAll(mazeWalls());
    addAll(screenEdgeBoundaries(game.camera));
    addAll(pelletsAndSuperPellets(pelletsRemainingNotifier));

    multiGhostAdderTimer();
    game.winOrLoseGameListener();
  }

  @override
  void update(double dt) {
    super.update(dt);
    now = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    game.startTimer(); //starts off timer first time drag
    Vector2 eventVector = event.canvasPosition - game.canvasSize / 2;
    if (iOS) {
      _lastDragAngle = 10;
    } else {
      _lastDragAngle = atan2(eventVector.x, eventVector.y);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    Vector2 eventVector = event.canvasStartPosition - game.canvasSize / 2;
    double eventVectorLengthProportion =
        (event.canvasStartPosition - game.canvasSize / 2).length /
            (min(game.canvasSize.x, game.canvasSize.y) / 2);
    if (_lastDragAngle != 10) {
      double spinMultiplier = 4 * min(1, eventVectorLengthProportion / 0.75);
      double currentAngleTmp = atan2(eventVector.x, eventVector.y);
      double angleDelta =
          convertToSmallestDeltaAngle(currentAngleTmp - _lastDragAngle);
      _gravityTargetAngle = _gravityTargetAngle + angleDelta * spinMultiplier;
      setGravity(Vector2(cos(_gravityTargetAngle), sin(_gravityTargetAngle)));
    }
    _lastDragAngle = atan2(eventVector.x, eventVector.y);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (clickAndDrag) {
      _lastDragAngle = 10;
    }
  }

  void setGravity(Vector2 targetGravity) {
    if (physicsOn) {
      gravity = targetGravity;
      if (normaliseGravity) {
        gravity = gravity.normalized() * 50;
      }
      if (screenRotates) {
        game.camera.viewfinder.angle = -atan2(gravity.x, gravity.y);
      }
    }
  }
}