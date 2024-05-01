import 'dart:math';
import 'dart:ui';
import '../endless_world.dart';

import 'package:endless_runner/flame_game/constants.dart';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';

/// The [Background] is a component that is composed of multiple scrolling
/// images which form a parallax, a way to simulate movement and depth in the
/// background.
class Background extends ParallaxComponent{
  Background({required this.speed, required this.world});

  final double speed;
  final EndlessWorld world;

  @override
  Future<void> onLoad() async {
    final layers = [
      ParallaxImageData('dash/Pac-Man.png'),
      //ParallaxImageData('scenery/clouds.png'),
      //ParallaxImageData('scenery/cliffs.png'),
      //ParallaxImageData('scenery/trees.png'),
      //ParallaxImageData('scenery/ground.png'),
    ];

    anchor = Anchor.center;
    position = Vector2(ksizex/2,ksizey/2);
    scale = Vector2(gameScaleFactor,gameScaleFactor);
    angle = 0;

    // The base velocity sets the speed of the layer the farthest to the back.
    // Since the speed in our game is defined as the speed of the layer in the
    // front, where the player is, we have to calculate what speed the layer in
    // the back should have and then the parallax will take care of setting the
    // speeds for the rest of the layers.
    final baseVelocity = Vector2(speed / pow(2, layers.length), 0);

    // The multiplier delta is used by the parallax to multiply the speed of
    // each layer compared to the last, starting from the back. Since we only
    // want our layers to move in the X-axis, we multiply by something larger
    // than 1.0 here so that the speed of each layer is higher the closer to the
    // screen it is.
    final velocityMultiplierDelta = Vector2(2.0, 0.0);


    parallax = await game.loadParallax(
      layers,
      baseVelocity: baseVelocity,
      velocityMultiplierDelta: velocityMultiplierDelta,
      filterQuality: FilterQuality.none,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (screenRotates) {
      angle = world.worldAngle;
    }
  }

}
