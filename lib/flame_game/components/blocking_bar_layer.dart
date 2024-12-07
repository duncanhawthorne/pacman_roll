import '../maze.dart';
import 'wrapper_no_events.dart';

class BlockingBarWrapper extends WrapperNoEvents {
  @override
  final int priority = 1000;

  @override
  void reset() {
    if (children.isNotEmpty) {
      removeAll(children);
    }
    addAll(maze.mazeBlockingWalls());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    reset();
  }
}
