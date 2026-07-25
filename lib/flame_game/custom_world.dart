import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../utils/constants.dart';
import 'components/base_component.dart';
import 'components/blocking_bar_layer.dart';
import 'components/ghost_layer.dart';
import 'components/pacman_layer.dart';
import 'components/pellet_layer.dart';
import 'components/wall_dynamic_layer.dart';
import 'components/wall_layer.dart';
import 'custom_game.dart';
import 'managers/death_reset.dart';
import 'managers/drag_rotation.dart';
import 'managers/engine_auto_pauser.dart';
import 'managers/mouse_move.dart';

/// The game world responsible for managing the lifecycle, physics, and hierarchy
/// of all active gameplay elements in the Pacman game.
///
/// This includes the player, enemies, obstacles, and game state managers.
///
/// **Mixins:**
/// * [DragCallbacks]: Enables the world to intercept and respond to user touch,
///   drag, and mouse interactions.
/// * [HasGameReference]: Provides direct access to the parent [CustomGame]
///   instance via the `game` property.
class CustomWorld extends Forge2DWorld
    with HasGameReference<CustomGame>, DragCallbacks {
  /// Private constructor to enforce the singleton pattern.
  CustomWorld._();

  /// Factory constructor that returns the single initialized instance of [CustomWorld].
  ///
  /// Throws an [AssertionError] if an attempt is made to instantiate more than once.
  factory CustomWorld() {
    assert(
      _instance == null,
      'CustomWorld is a singleton and can only be initialized once.',
    );
    _instance ??= CustomWorld._();
    return _instance!;
  }

  /// The internal singleton instance of the world.
  static CustomWorld? _instance;

  /// Vector tracking the directional sign of the world's gravity.
  final Vector2 gravitySign = Vector2.zero();

  /// Internal tracking list containing all system managers and game wrappers.
  final List<BaseComponent> _wrappers = <BaseComponent>[];

  /// A passive visual container used to hold components that do not require
  /// gesture event dispatching.
  final BaseComponent _noEvents = BaseComponent();

  // ==========================================
  // Core Component & Manager Definitions
  // ==========================================

  /// Layer managing all Pacman instances.
  final Pacmans pacmans = Pacmans();

  /// Layer managing all ghost instances.
  final Ghosts ghosts = Ghosts();

  /// Layer managing pellets and power-ups.
  final PelletWrapper pellets = PelletWrapper();

  /// Layer managing static walls.
  final WallWrapper _walls = WallWrapper();

  /// Layer managing visual overlay on edge boundaries.
  final BlockingBarWrapper _blocking = BlockingBarWrapper();

  /// Layer managing dynamic moving walls.
  final MovingWallWrapper _movingWalls = MovingWallWrapper();

  /// Manager for character resets after death.
  final DeathReset deathReset = DeathReset();

  /// Logic for auto-pausing the engine during inactivity.
  final EngineAutoPauser autoPauser = EngineAutoPauser();

  /// Handler for maze rotation gestures.
  late final DragRotation dragRotate = DragRotation()..world = this;

  /// Handler for mouse move maze rotation gestures.
  late final MouseMove mouseMove = MouseMove();

  /// Resets the game state for all managed wrappers.
  ///
  /// If [firstRun] is true, the reset cycle is skipped, as components are
  /// expected to initialize to their default states natively during [onLoad].
  void reset({bool firstRun = false}) {
    if (!firstRun) {
      for (final BaseComponent wrapper in _wrappers) {
        assert(
          wrapper.isLoaded,
          'Attempted to reset a component that has not finished loading: $wrapper',
        );
        wrapper.reset();
      }
    }
  }

  /// Signals all tracked wrappers to begin their primary game execution routines.
  void start() {
    for (final BaseComponent wrapper in _wrappers) {
      wrapper.start();
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Mount the non-event container directly to the world.
    add(_noEvents);

    // Register all core gameplay elements, configuration layers, and systems.
    _wrappers.addAll(<BaseComponent>[
      pacmans,
      ghosts,
      if (!enableRotationRaceMode) pellets,
      _walls,
      _blocking,
      if (enableMovingWalls) _movingWalls,
      deathReset,
      autoPauser,
      dragRotate,
      mouseMove,
      game.session,
      game.lifecycle,
      game.playback,
      game.dialogs,
    ]);

    /// Optimization: Nesting wrappers inside [_noEvents] keeps the flat count
    /// of root-level world components minimal. This speeds up Flame's internal
    /// element tree traversals, significantly optimizing gesture hit-testing
    /// methods like `deliverAtPoint` during drag interactions.
    _wrappers.forEach(_noEvents.add);

    reset(firstRun: true);
  }

  @override
  void onRemove() {
    _wrappers.clear();
    super.onRemove();
  }

  // ==========================================
  // Drag Input Event Handlers
  // ==========================================

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    dragRotate.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    dragRotate.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    dragRotate.onDragEnd(event);
  }
}
