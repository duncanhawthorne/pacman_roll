import 'dart:math';

import 'package:flame_forge2d/flame_forge2d.dart';

import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:flame/src/events/messages/pointer_move_event.dart'
    as dhpointer_move_event;

import 'components/point.dart';
import 'components/wall.dart';
import 'game_screen.dart';
import 'components/obstacle.dart';
import 'components/player.dart';
import 'components/boat.dart';
import 'components/ball.dart';
import 'constants.dart';
import 'helper.dart';

import 'package:sensors_plus/sensors_plus.dart';

import 'package:flutter/foundation.dart';

import '../audio/audio_controller.dart';

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

  Vector2 dhdragStart = Vector2(0, 0);
  Vector2 dhdragLatest = Vector2(0, 0);

  /// Used to see what the current progress of the player is and to update the
  /// progress if a level is finished.
  final PlayerProgress playerProgress;

  /// The speed is used for determining how fast the background should pass by
  /// and how fast the enemies and obstacles should move.
  late double speed = _calculateSpeed(level.number * 5);

  /// In the [scoreNotifier] we keep track of what the current score is, and if
  /// other parts of the code is interested in when the score is updated they
  /// can listen to it and act on the updated value.
  final scoreNotifier = ValueNotifier(0);
  late Player player;
  late final Boat boat;
  late final Ball ball;
  late final RectangleComponent rope;
  late PolygonComponent poly;
  late final DateTime timeStarted;
  Vector2 get size => (parent as FlameGame).size;
  int levelCompletedIn = 0;
  late final AudioController audioController;
  get getAudioController => audioController;

  /// The random number generator that is used to spawn periodic components.
  final Random _random;

  /// The gravity is defined in virtual pixels per second squared.
  /// These pixels are in relation to how big the [FixedResolutionViewport] is.
  @override
  final Vector2 gravity = Vector2(0, 100);

  /// Where the ground is located in the world and things should stop falling.
  late final double groundLevel = (size.y / 2) - (size.y / 5);

  @override
  Future<void> onLoad() async {
    ksizex = size.x;
    ksizey = size.y;
    // Used to keep track of when the level started, so that we later can
    // calculate how long time it took to finish the level.
    timeStarted = DateTime.now();

    // ignore: deprecated_member_use
    if (android) {
      accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          if (android) {
            //p(event);
            gravity = Vector2(event.y, event.x - 5) * 18; //NOTE dimensions flipped
            globalGravity.x = event.x - 5; //NOTE dimensions not flipped
            globalGravity.y = event.y; //NOTE dimensions not flipped
          }
        },
        onError: (error) {
          // Logic to handle error
          // Needed for Android in case sensor is not available
        },
        cancelOnError: true,
      );
    }

    if (realsurf) {
      if (realsurf) {
        boat = Boat(
          position: Vector2(0, size.y / 4 / dzoom),
          addScore: addScore,
          resetScore: resetScore,
        );
        add(boat);
      }
      if (realsurf) {
        player.target = boat.position;

        rope = RectangleComponent(
          position: Vector2(10.0, 15.0),
          size: Vector2.all(100),
          angle: pi / 2,
          anchor: Anchor.center,
        );
        add(rope);
      }

      if (realsurf) {
        //bad things
        add(
          SpawnComponent.periodRange(
            factory: (_) => Obstacle.random(
              random: _random,
              canSpawnTall: false,
            ),
            minPeriod: 1.0,
            maxPeriod: 2.0,
            area: Rectangle.fromPoints(
              Vector2(-size.x / 2, size.y / 2 + MiniPellet.spriteSize.y) / dzoom,
              Vector2(size.x / 2, size.y / 2 + MiniPellet.spriteSize.y) / dzoom,
            ),
            random: _random,
          ),
        );
      }

      if (realsurf) {
        //good things
        add(
          SpawnComponent.periodRange(
            factory: (_) => MiniPellet(),
            minPeriod: 1.0,
            maxPeriod: 2.0,
            area: Rectangle.fromPoints(
              Vector2(-size.x / 2, size.y / 2 + MiniPellet.spriteSize.y) / dzoom,
              Vector2(size.x / 2, size.y / 2 + MiniPellet.spriteSize.y) / dzoom,
            ),
            random: _random,
          ),
        );
      }
    }

    player = Player(isGhost: false
        //position: Vector2(boat.position.x, boat.position.y),
        //addScore: addScore,
        //resetScore: resetScore,
        );
    add(player);

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(seconds: i), () {
        addGhost(this);
      });
    }

    addPillsAndPowerPills(this);

    // When the player takes a new point we check if the score is enough to
    // pass the level and if it is we calculate what time the level was passed
    // in, update the player's progress and open up a dialog that shows that
    // the player passed the level.
    scoreNotifier.addListener(() {
      if (scoreNotifier.value >= level.winScore) {
        final levelTime = (DateTime.now().millisecondsSinceEpoch -
                timeStarted.millisecondsSinceEpoch) /
            1000;

        levelCompletedIn = levelTime.round();

        playerProgress.setLevelFinished(level.number, levelCompletedIn);
        game.pauseEngine();
        game.overlays.add(GameScreen.winDialogKey);
      }
    });
  }

  @override
  void onMount() {
    super.onMount();
    // When the world is mounted in the game we add a back button widget as an
    // overlay so that the player can go back to the previous screen.
    game.overlays.add(GameScreen.backButtonKey);
  }

  @override
  void onRemove() {
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
  void update(double dt) {
    super.update(dt);
    if (realsurf) {
      rope.position = (boat.position + player.position) / 2;
      rope.size = Vector2(
          10000 /
              dzoom /
              dzoom /
              max(100, (boat.position - player.position).length),
          (boat.position - player.position).length);
      rope.angle =
          -(player.position - boat.position).angleToSigned(Vector2(0, 1));
    }
  }

  /// [onTapDown] is called when the player taps the screen and then calculates
  /// if and how the player should jump.
  @override
  void onTapDown(TapDownEvent event) {
    //audioController.playSfx(SfxType.damage);
    if (realsurf) {
      boat.position = getTarget(event.localPosition, size);
      player.target = boat.position;
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (realsurf) {
      boat.position = getTarget(event.localPosition, size);
      player.target = boat.position;
    }
    if (addRandomWalls) {
      dhdragStart = event.localPosition;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (addRandomWalls) {
      add(Wall(dhdragStart, dhdragLatest));
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (realsurf) {
      boat.position = getTarget(event.localStartPosition, size);
      player.target = boat.position;
    }
    if (addRandomWalls) {
      dhdragLatest = event.localStartPosition;
    }
  }

  @override
  void onPointerMove(dhpointer_move_event.PointerMoveEvent event) {
    if (!android) {
      gravity = event.localPosition - player.position;
    }
    if (realsurf) {
      boat.position = getTarget(event.localPosition, size);
      player.target = boat.position;
    }
  }

  /// A helper function to define how fast a certain level should be.
  static double _calculateSpeed(int level) => (100 + (level * 100)) / dzoom;
}
