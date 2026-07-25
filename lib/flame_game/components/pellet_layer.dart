import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../maze/maze.dart';
import '../custom_game.dart';
import 'base_component.dart';
import 'mini_pellet.dart';
import 'super_pellet.dart';

/// A container component that manages and renders all pellets in the maze.
class PelletWrapper extends BaseComponent
    with HasGameReference<CustomGame>, Snapshot {
  @override
  final int priority = -2;

  /// Indicates if the player has collected all pellets (win condition).
  bool get winState =>
      ((!kDebugMode || isMounted) && pelletsRemainingNotifier.value <= 0);

  /// Tracks the total number of pellets remaining in the maze.
  final ValueNotifier<int> pelletsRemainingNotifier = ValueNotifier<int>(0);

  @override
  Future<void> reset() async {
    if (children.isNotEmpty) {
      removeAll(children);
    }
    final bool superPelletsEnabled = game.level.superPelletsEnabled;
    for (Vector2 pos in maze.itemFactory.miniPelletPositions(
      superPelletsEnabled,
    )) {
      add(
        MiniPellet(
          position: pos,
          pelletsRemainingNotifier: pelletsRemainingNotifier,
        ),
      );
    }
    if (superPelletsEnabled) {
      for (Vector2 pos in maze.itemFactory.superPelletPositions()) {
        add(
          SuperPellet(
            position: pos,
            pelletsRemainingNotifier: pelletsRemainingNotifier,
          ),
        );
      }
    }
    clearSnapshot();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    pelletsRemainingNotifier.addListener(() {
      assert(!isRemoving);
      clearSnapshot();
    });
    await reset();
    renderSnapshot = true;
  }

  @override
  void updateTree(double dt) {
    // no point traversing large list of children as nothing to update
    // so cut short the updateTree here
    //super.updateTree(dt);
  }
}
