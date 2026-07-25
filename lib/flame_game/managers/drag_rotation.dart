import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';

import '../../utils/constants.dart';
import '../components/base_component.dart';
import '../components/physics_ball.dart';
import '../custom_game.dart';
import '../custom_world.dart';
import '../effects/remove_effects.dart';
import '../effects/rotate_effect.dart';
import 'playback.dart';

/// Manages the rotation of the maze based on user drag input.
///
/// This class handles the conversion of drag events into maze rotation,
/// which in turn affects the gravity in the game world.
class DragRotation extends BaseComponent with HasGameReference<CustomGame> {
  late final CustomWorld world;

  double _canvasRadiusInv = 1.0;
  final Map<int, double?> _fingersLastDragAngle = <int, double?>{};
  bool _cameraRotatable = true;

  /// Initiates a sliding reset of the maze angle to its default.
  void resetSlide(VoidCallback callback) {
    assert(game.playState == PlayState.flourish);
    _cameraRotatable = false;
    resetSlideAngle(game.camera.viewfinder, onComplete: callback);
  }

  /// Resets the maze angle to zero instantly and stops any ongoing rotation effects.
  @override
  Future<void> reset() async {
    //stop any rotation effect added to camera
    //note, still leaves flourish variable hot, so fix below
    removeEffects(game.camera.viewfinder);
    setMazeAngle(0, noStartRegularItems: true);
    _cameraRotatable = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _canvasRadiusInv = 1 / (min(game.canvasSize.x, game.canvasSize.y) / 2);
  }

  /// Handles the locked cursor moving to rotate the maze.
  void onLockedCursorMove(double dx, double dy) {
    game.lifecycle.resumeGame();

    final double mouseDelta = dx + dy;
    const double mouseSensitivity = 0.005;

    if (mouseDelta != 0) {
      _moveMazeAngleByDelta(mouseDelta * mouseSensitivity);
    }
  }

  /// Handles the start of a drag event to begin rotating the maze.
  void onDragStart(DragStartEvent event) {
    if (isiOSWeb) {
      /// Enter null as first angle is unreliable
      /// And fix in [onDragUpdate] below where angle is reliable
      _fingersLastDragAngle[event.pointerId] = null;
    } else {
      _fingersLastDragAngle[event.pointerId] = atan2(
        event.canvasPosition.x - game.canvasSize.x * 0.5,
        event.canvasPosition.y - game.canvasSize.y * 0.5,
      );
    }
  }

  /// Handles the update of a drag event, calculating the rotation delta and applying it.
  void onDragUpdate(DragUpdateEvent event) {
    game.lifecycle.resumeGame();
    final double dx = event.canvasStartPosition.x - game.canvasSize.x * 0.5;
    final double dy = event.canvasStartPosition.y - game.canvasSize.y * 0.5;
    final double fingerCurrentDragAngle = atan2(dx, dy);
    final double? lastAngle = _fingersLastDragAngle[event.pointerId];
    if (lastAngle != null) {
      final double eventVectorLengthProportion =
          sqrt(dx * dx + dy * dy) * _canvasRadiusInv;
      final double angleDelta = smallAngle(fingerCurrentDragAngle - lastAngle);
      const double maxSpinMultiplierRadiusInv = 1 / 0.75;
      final double spinMultiplier =
          4 *
          game.level.spinSpeedFactor *
          min(1, eventVectorLengthProportion * maxSpinMultiplierRadiusInv);
      _moveMazeAngleByDelta(angleDelta * spinMultiplier);
    }

    /// For iOSWeb first entry is [onDragStart] enters null,
    /// so now switch null to current angle to track going forward
    /// like on other platforms
    _fingersLastDragAngle[event.pointerId] = fingerCurrentDragAngle;
  }

  /// Handles the end of a drag event.
  void onDragEnd(DragEndEvent event) {
    _fingersLastDragAngle.remove(event.pointerId);
  }

  /// Moves the maze angle by the specified delta if rotation is allowed.
  void _moveMazeAngleByDelta(double angleDelta) {
    if (_cameraRotatable &&
        game.isLive &&
        (game.playState == PlayState.gaming ||
            game.playState == PlayState.flourish)) {
      setMazeAngle(
        _cameraAngle + (_reversedRotation ? -angleDelta : angleDelta),
      );
    }
  }

  /// The current direction of gravity based on the maze rotation.
  final Vector2 downDirection = Vector2.zero();

  static final Vector2 _reusableVector = Vector2.zero();

  /// Direction of gravity in physics units.
  Vector2 get _downDirectionPhysics => _reusableVector
    ..setFrom(downDirection)
    ..scale(physicsScale);

  /// Current angle pointing towards "down" in the maze.
  double get downAngle => -atan2(downDirection.x, downDirection.y);

  static const bool _updateGravityOnRotation = true;

  static const bool _reversedRotation = false;

  static const bool _kRotatingCamera = !kDebugMode || true;

  /// Gets the current camera (maze) angle.
  double get _cameraAngle =>
      _kRotatingCamera ? game.camera.viewfinder.angle : _debugFakeAngle;

  /// Sets the current camera (maze) angle.
  set _cameraAngle(double z) =>
      _kRotatingCamera ? game.camera.viewfinder.angle = z : _debugFakeAngle = z;

  double _debugFakeAngle = 0;

  /// Sets the maze angle and updates gravity and related game state.
  void setMazeAngle(double angle, {bool noStartRegularItems = false}) {
    if (!noStartRegularItems &&
        game.playState != PlayState.flourish &&
        !game.session.isWonOrLost) {
      game.lifecycle.startRegularItems();
    }
    Playback.recordMode ? game.playback.recordAngle(angle) : null; //disabled
    _cameraAngle = angle;
    downDirection
      ..setValues(-sin(angle), cos(angle))
      ..scale(game.level.levelSpeed);

    if (_updateGravityOnRotation) {
      /// The gravity is defined in virtual pixels per second squared.
      /// These pixels are in relation to how big the [FixedResolutionViewport] is.

      world.gravity = _downDirectionPhysics;
      world.gravitySign.setValues(
        world.gravity.x.sign,
        world.gravity.y.sign,
      ); //used every frame
    }
  }
}
