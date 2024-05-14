import 'package:flame/experimental.dart';

import '../helper.dart';

import '../endless_world.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../constants.dart';

class MiniPelletCircle extends CircleComponent {
  MiniPelletCircle({required position})
      : super(
            radius:
                getSingleSquareWidth() * miniPelletAndSuperPelletScaleFactor / 2 * 1/ 3,
            position: position,
            anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox(collisionType: CollisionType.passive));
  }
}
