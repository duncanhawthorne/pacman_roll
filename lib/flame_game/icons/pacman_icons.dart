import 'package:flame/geometry.dart';
import 'package:flutter/material.dart';

import '../dialogs/game_overlays.dart';
import '../pacman_game.dart';
import 'pacman_sprites.dart';

Widget animatedPacmanIcon(PacmanGame game, int index) {
  return ValueListenableBuilder<int>(
      valueListenable: game.world.pacmans.pacmanDyingNotifier,
      builder: (BuildContext context, int value, Widget? child) {
        return TweenAnimationBuilder<int>(
            tween: IntTween(
                begin: pacmanCircleIncrements ~/ 4,
                end: pacmanCircleIncrements ~/ 4 +
                    ((pacmanCircleIncrements * 3) ~/ 4) *
                        (game.world.pacmans.pacmanDyingNotifier.value - index)
                            .clamp(0, 1)),
            duration: Duration(
                milliseconds:
                    game.world.pacmans.pacmanDyingNotifier.value <= index
                        ? 0 //when reset game
                        : kPacmanDeadResetTimeAnimationMillis),
            builder: (BuildContext context, int val, __) {
              return _pacmanIconCache[val];
            });
      });
}

final List<Widget> _pacmanIconCache = List<Widget>.generate(
    pacmanCircleIncrements + 1,
    (int index) => _pacmanIconFromPainter(mouthSize: index));

Widget _pacmanIconFromPainter({int mouthSize = pacmanCircleIncrements ~/ 4}) {
  return CustomPaint(
      size: const Size(pacmanIconSize, pacmanIconSize),
      painter: _PacmanPainter(mouthSize: mouthSize));
}

final Rect _pacmanRect = Rect.fromCenter(
    center: const Offset(pacmanIconSize / 2, pacmanIconSize / 2),
    width: pacmanIconSize.toDouble(),
    height: pacmanIconSize.toDouble());

class _PacmanPainter extends CustomPainter {
  _PacmanPainter({required this.mouthSize});

  int mouthSize;

  @override
  void paint(Canvas canvas, Size size) {
    double mouthWidth = mouthSize / pacmanCircleIncrements;
    mouthWidth = mouthWidth.clamp(0, 1);
    canvas.drawArc(_pacmanRect, tau / 2 + tau * ((mouthWidth / 2) + 0.5),
        tau * (1 - mouthWidth), true, pacmanPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
