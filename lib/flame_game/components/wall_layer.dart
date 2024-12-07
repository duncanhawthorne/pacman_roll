import '../maze.dart';
import 'wrapper_no_events.dart';

class WallWrapper extends WrapperNoEvents {
  @override
  void reset() {
    if (children.isNotEmpty) {
      removeAll(children);
    }
    addAll(maze.mazeWalls());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    reset();
  }
}
