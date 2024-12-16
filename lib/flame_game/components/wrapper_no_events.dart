import 'package:flame/components.dart';

/// Use wrappers to minimise number of components directly in main world
/// Helps due to loops running through all child components
/// Especially on drag events deliverAtPoint
/// Also set IgnoreEvents to speed up deliverAtPoint for all components queried

class WrapperNoEvents extends PositionComponent with IgnoreEvents {
  Future<void> reset() async {}

  void start() {}
}
