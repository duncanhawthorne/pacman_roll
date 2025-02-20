import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../maze.dart';
import '../pacman_game.dart';
import 'wrapper_no_events.dart';

/// Use wrappers to minimise number of components directly in main world
/// Helps due to loops running through all child components
/// Especially on drag events deliverAtPoint
/// Also set IgnoreEvents to speed up deliverAtPoint for all components queried

class PelletWrapper extends WrapperNoEvents
    with HasGameReference<PacmanGame>, Snapshot {
  @override
  final int priority = -2;

  final ValueNotifier<int> pelletsRemainingNotifier = ValueNotifier<int>(0);

  @override
  Future<void> reset() async {
    if (children.isNotEmpty) {
      removeAll(children);
    }
    await addAll(
      maze.pellets(game.level.superPelletsEnabled, pelletsRemainingNotifier),
    );
    clearSnapshot();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    pelletsRemainingNotifier.addListener(() {
      clearSnapshot();
    });
    await reset();
    renderSnapshot = false;
  }

  @override
  void updateTree(double dt) {
    // no point traversing large list of children as nothing to update
    // so cut short the updateTree here
    //super.updateTree(dt);
  }
}
