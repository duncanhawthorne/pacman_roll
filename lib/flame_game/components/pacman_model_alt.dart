import 'package:flame/effects.dart';
import '../constants.dart';
import '../helper.dart';
import 'dart:math';
import 'package:flame/components.dart';
import 'dart:core';
import 'dart:ui' as ui;
import 'dart:ui';

ui.Image pacmanStandardImageAlt() {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  const mouthWidth = pacmanMouthWidthDefault;
  canvas.drawArc(pacmanRect, 2 * pi * ((mouthWidth / 2) + 0.5),
      2 * pi * (1 - mouthWidth), true, yellowPacmanPaint);
  return recorder.endRecording().toImageSync(100, 100);
}

ui.Image pacmanMouthClosedImageAlt() {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  const mouthWidth = 0;
  canvas.drawArc(pacmanRect, 2 * pi * ((mouthWidth / 2) + 0.5),
      2 * pi * (1 - mouthWidth), true, yellowPacmanPaint);
  return recorder.endRecording().toImageSync(100, 100);
}

pureVectorPacmanAlt() {
  double pfrac = pacmanMouthWidthDefault.toDouble();
  double pangle = pfrac * 2 * pi / 2;
  return ClipComponent.polygon(
    points: [
      Vector2(1, 0),
      Vector2(0, 0),
      Vector2(0, 1),
      Vector2(1, 1),
      pfrac > 0.5 ? Vector2(0, 1) : Vector2(1, 1),
      Vector2(0.5 + cos(pangle) / 2, 0.5 + sin(pangle) / 2),
      Vector2(0.5, 0.5),
      Vector2(0.5 + cos(pangle) / 2, 0.5 - sin(pangle) / 2),
      pfrac > 0.5 ? Vector2(0, 0) : Vector2(1, 0),
      Vector2(1, 0),
    ],
    position: Vector2(0, 0),
    size: Vector2.all(blockWidth()),
    children: [
      CircleComponent(
          radius: blockWidth() / 2, paint: yellowPacmanPaint),
    ],
  );
}

pureVectorPacmanTwoAlt() {
  CircleComponent d = CircleComponent(
      radius: blockWidth() / 2,
      paint: yellowPacmanPaint,
      anchor: Anchor.topLeft,
      position: Vector2(0, 0));
  PolygonComponent b = PolygonComponent([
    Vector2(
        1 * blockWidth(),
        -1 *
            blockWidth() *
            tan(1 / 2 * pacmanMouthWidthDefault * 2 * pi)),
    Vector2(0, 0),
    Vector2(1 * blockWidth(),
        1 * blockWidth() * tan(1 / 2 * pacmanMouthWidthDefault * 2 * pi))
  ],
      anchor: Anchor.centerLeft,
      position: Vector2.all(blockWidth() / 2),
      paint: blackBackgroundPaint);
  ClipComponent c = ClipComponent.circle(
      anchor: Anchor.center,
      size: Vector2.all(blockWidth()),
      children: [d, b]);

  final effectClose = ScaleEffect.to(
    Vector2(1, 0.0),
    EffectController(duration: kPacmanHalfEatingResetTimeMillis / 1000),
  );
  final effectOpen = ScaleEffect.to(
    Vector2(1, 1),
    EffectController(duration: kPacmanHalfEatingResetTimeMillis / 1000),
  );
  final effect = SequenceEffect([effectClose, effectOpen]);

  c.children.last.add(effect);

  return c;
}
