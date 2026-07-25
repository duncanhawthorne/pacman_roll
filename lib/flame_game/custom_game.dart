import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../app_lifecycle/app_lifecycle.dart';
import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../style/palette.dart';
import '../utils/helper.dart';
import '../utils/src/workarounds.dart';
import 'custom_world.dart';
import 'game_screen.dart';
import 'managers/dialog_manager.dart';
import 'managers/game_lifecycle.dart';
import 'managers/game_session.dart';
import 'managers/playback.dart';
import 'maze/maze.dart';

/// The core physics-driven game loop class that mounts inside the [GameWidget].
///
/// This class handles the initialization, state management, and lifecycle events
/// of the Pacman simulation. It configures:
/// * A [FixedResolutionViewport] mapping to a square [worldSquareSize] canvas to
///   ensure aspect ratio consistency across diverse device screens.
/// * A specialized [Forge2DGame] simulation utilizing a dedicated [CustomWorld].
/// * Custom QuadTree broadphase collision optimizations appropriate for high-density maps.
///
/// Both the world and fixed-resolution camera configurations are directly initialized
/// through the super constructor to guarantee stable object layout scaling upon instantiation.
///
/// Note flame_forge2d has a maximum allowed speed for physical objects.
/// Reducing map size 30x, scaling up gravity 30x, & zooming 30x changes nothing,
/// but reduces chance of hitting maximum allowed speed.
const double _visualZoomMultiplier = 0.92;

/// Determines the baseline layout coordinates and relative speed of the game.
const double mapSizeScale = 1;
const double _kVirtualGameSize = 1700 / 30;
const double worldSquareSize = _kVirtualGameSize * mapSizeScale;

class CustomGame extends Forge2DGame<CustomWorld>
    with
        HasQuadTreeCollisionDetection<CustomWorld>,
        SingleGameInstance,
        HasTimeScale {
  /// Private generative constructor initialized by the singleton factory wrapper.
  CustomGame._({
    required this.level,
    required int mazeId,
    required this.playerProgress,
    required this.audioController,
    required this.appLifecycleStateNotifier,
  }) : super(
         world: CustomWorld(),
         camera: CameraComponent.withFixedResolution(
           width: worldSquareSize,
           height: worldSquareSize,
         )..viewfinder.zoom = _visualZoomMultiplier,
         metersToPixels: 1, //pixels per meter
       ) {
    maze.mazeId = mazeId;
  }

  /// Factory constructor managing a single global instance of [CustomGame].
  ///
  /// On subsequent calls, instead of re-instantiating, it updates the mutable configuration properties
  /// of the existing instance and issues an internal soft reset sequence.
  factory CustomGame({
    required GameLevel level,
    required int mazeId,
    required PlayerProgress playerProgress,
    required AudioController audioController,
    required AppLifecycleStateNotifier appLifecycleStateNotifier,
  }) {
    if (_instance == null) {
      _instance = CustomGame._(
        level: level,
        mazeId: mazeId,
        playerProgress: playerProgress,
        audioController: audioController,
        appLifecycleStateNotifier: appLifecycleStateNotifier,
      );
    } else {
      maze.mazeId = mazeId;
      _instance!
        ..level = level
        ..reset(firstRun: false, showStartDialog: true);
    }
    return _instance!;
  }

  /// Cached reference enforcing the singleton instance pattern.
  static CustomGame? _instance;

  /// Holds structural metadata configuration relating to the current stage/level.
  GameLevel level;

  /// General audio controller handling sound effects, loops, and device integrations.
  final AudioController audioController;

  /// Notifier handling application focus state changes from the OS host platform layer.
  final AppLifecycleStateNotifier appLifecycleStateNotifier;

  /// Component mapping user persistent state progress records.
  final PlayerProgress playerProgress;

  /// Manages the scoring, win/loss conditions, and session data.
  final GameSession session = GameSession();

  /// Manages the game lifecycle, pausing/resuming, and stopwatch.
  final GameLifecycle lifecycle = GameLifecycle();

  /// Handles recording and replaying of maze rotations.
  late final Playback playback = Playback()..game = this;

  /// Manages game overlays and dialog visibility.
  late final DialogManager dialogs = DialogManager()..game = this;

  /// Evaluates whether the simulation frame is ready, running, and active inside the widget tree.
  bool get isLive => !paused && isLoaded && isMounted && timeScale != 0;

  @override
  Color backgroundColor() => Palette.background.color;

  @override
  void onGameResize(Vector2 size) {
    camera.viewport = FixedResolutionViewport(
      resolution: _sanitizeScreenSize(size),
    );
    super.onGameResize(size);
  }

  /// Resets game and world.
  ///
  /// * Set [firstRun] to `true` on initial canvas allocation to avoid resetting unbuilt items.
  /// * Set [showStartDialog] to `true` to push standard overlays over the current viewport layer.
  void reset({bool firstRun = false, bool showStartDialog = false}) {
    if (!firstRun) {
      assert(world.isLoaded);
      world.reset();
    }
    collisionDetection.broadphase.tree.optimize();
    if (showStartDialog) {
      playState = playback.isPlaybackAppropriate()
          ? PlayState.playbackMode
          : PlayState.levelChooseScreen;
    }
  }

  /// Orchestrates a clean state wipe sequence and immediately begins game loops.
  void resetAndStart() {
    reset();
    start();
  }

  /// Begins primary gameplay activities, including audio and world updates.
  void start() {
    audioController
      ..workaroundiOSSafariAudioOnUserInteraction()
      ..playSfx(SfxType.startMusic);
    world.start();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    bugFixes();
    initializeCollisionDetection(
      mapDimensions: Rect.fromLTWH(
        -maze.dimensions.mazeWidth / 2,
        -maze.dimensions.mazeHeight / 2,
        maze.dimensions.mazeWidth,
        maze.dimensions.mazeHeight,
      ),
    ); // assumes maze size won't change
    reset(firstRun: true, showStartDialog: true);
  }

  @override
  Future<void> onRemove() async {
    await audioController.stopAllSounds();
    super.onRemove();
  }

  PlayState _playState = PlayState.playbackMode;

  /// Returns the current high-level state of the game.
  PlayState get playState => _playState;

  /// Updates the game state and handles transition logic (e.g., showing/hiding overlays).
  set playState(PlayState s) => _setState(s);

  /// State handler managing state shifts.
  void _setState(PlayState s) {
    logGlobal(s);
    final PlayState origState = _playState;
    _playState = s;
    switch (s) {
      case PlayState.playbackMode:
        playback.enable();
        dialogs.switchTo(GameScreen.beginDialogKey);
      case PlayState.levelChooseScreen:
        playback.disable();
        dialogs.switchTo(GameScreen.startDialogKey);
      case PlayState.gaming:
        playback.disable();
        if (!session.isWonOrLost && !lifecycle.stopwatchStarted) {
          dialogs.clean();
        }
        if (origState == PlayState.levelChooseScreen) {
          start();
        }
      case PlayState.flourish:
        null;
      case PlayState.unflourish:
        assert(origState == PlayState.flourish);
        if (playback.isPlaybackAppropriate()) {
          playState = PlayState.playbackMode;
        } else {
          playState = PlayState.gaming;
        }
    }
  }
}

/// Helper recalculating appropriate canvas dimensions to ensure core square game area unchanged.
Vector2 _sanitizeScreenSize(Vector2 size) {
  final double aspectRatio = size.x / size.y;
  return size.x > size.y
      ? Vector2(worldSquareSize * aspectRatio, worldSquareSize)
      : Vector2(worldSquareSize, worldSquareSize / aspectRatio);
}

enum PlayState { playbackMode, levelChooseScreen, gaming, flourish, unflourish }
