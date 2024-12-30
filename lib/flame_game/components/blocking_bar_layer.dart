import 'dart:async';

import 'package:flame/components.dart';

import '../maze.dart';
import 'wrapper_no_events.dart';

class BlockingBarWrapper extends WrapperNoEvents with Snapshot {
  @override
  final int priority = 1000;

  @override
  Future<void> reset() async {
    if (children.isNotEmpty) {
      removeAll(children);
    }
    await addAll(maze.mazeBlockingWalls());
    clearSnapshot();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await reset();
  }

  @override
  void updateTree(double dt) {
    // no point traversing large list of children as nothing to update
    // so cut short the updateTree here
    //super.updateTree(dt);
  }
}
