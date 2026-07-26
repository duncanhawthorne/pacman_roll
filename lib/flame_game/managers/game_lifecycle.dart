import 'dart:ui';

import 'package:flame/components.dart';

import '../components/base_component.dart';
import '../custom_game.dart';
import '../custom_world.dart';

/// Manages the game's lifecycle, including pausing, resuming, and tracking play time.
///
/// Handles application lifecycle changes and coordinates the starting/stopping
/// of game elements.
class GameLifecycle extends BaseComponent
    with HasWorldReference<CustomWorld>, HasGameReference<CustomGame> {
  VoidCallback? _lifecycleListenerRef;
  bool _regularItemsStarted = false;

  bool _stopwatchStarted = false;

  /// Returns true if the game stopwatch has been started during this session.
  bool get stopwatchStarted => _stopwatchStarted;

  /// The stopwatch tracking active play time.
  final Timer stopwatch = Timer(double.infinity);

  /// Resets the flag indicating regular items are active.
  void noteThatSomeRegularItemHasStopped() {
    //so that will restart later
    _regularItemsStarted = false;
  }

  /// Pauses the game engine and time scale.
  void pauseGame() {
    game
      ..pause() //timeScale = 0;
      ..pauseEngine();
    noteThatSomeRegularItemHasStopped();
    //stopwatch.pause(); //shouldn't be necessary given timeScale = 0
  }

  /// Resumes the game engine and time scale if it was paused.
  void resumeGame() {
    if (game.paused || game.timeScale == 0) {
      noteThatSomeRegularItemHasStopped();
      game.timeScale = 1;
      game
        ..resume() //timeScale = 1.0;
        ..resumeEngine();
    }
  }

  /// Starts regular game activities and the stopwatch.
  void startRegularItems() {
    if (!_regularItemsStarted) {
      _regularItemsStarted = true;
      _stopwatchStarted = true; //once per reset
      stopwatch.resume();
      world.ghosts.startRegularItems();
    }
  }

  /// Stops regular game activities and pauses the stopwatch.
  void stopRegularItems() {
    noteThatSomeRegularItemHasStopped();
    stopwatch.pause();
    world.ghosts.stopRegularItems();
  }

  /// Sets up a listener for application lifecycle changes (e.g., backgrounding).
  void _lifecycleChangeListener() {
    _lifecycleListenerRef = () {
      if (game.appLifecycleStateNotifier.value == AppLifecycleState.hidden) {
        assert(!isRemoving);
        pauseGame();
      }
      if (game.appLifecycleStateNotifier.value == AppLifecycleState.resumed) {
        assert(!isRemoving);
        resumeGame();
      }
    };
    game.appLifecycleStateNotifier.addListener(_lifecycleListenerRef!);
  }

  @override
  Future<void> reset() async {
    stopRegularItems(); //duplicates other items, belt and braces only
    stopwatch
      ..pause()
      ..reset();
    _stopwatchStarted = false;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _lifecycleChangeListener(); //isn't disposed so run once, not on start()
  }

  @override
  Future<void> onRemove() async {
    if (_lifecycleListenerRef != null) {
      game.appLifecycleStateNotifier.removeListener(_lifecycleListenerRef!);
    }
    super.onRemove();
  }

  @override
  void update(double dt) {
    stopwatch.update(dt * game.timeScale); //stops stopwatch when timeScale = 0
    super.update(dt);
  }
}
