import 'package:flame/geometry.dart';
import 'package:flutter/material.dart';

import '../game_screen.dart';
import '../pacman_game.dart';
import 'pacman_sprites.dart';

Widget animatedPacmanIcon(PacmanGame game, int index) {
  return ValueListenableBuilder<int>(
      valueListenable: game.world.pacmans.pacmanDyingNotifier,
      builder: (BuildContext context, int value, Widget? child) {
        return TweenAnimationBuilder(
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
              return pacmanIconCache[val];
            });
      });
}

final pacmanIconCache = List.generate(pacmanCircleIncrements + 1,
    (int index) => _pacmanIconFromPainter(mouthSize: index));

// ignore: unused_element
Widget _pacmanIconFromFile({int mouthSize = pacmanCircleIncrements ~/ 4}) {
  return Image.asset('assets/images/$mouthSize.png',
      filterQuality: FilterQuality.none,
      height: statusWidgetHeight * statusWidgetHeightFactor,
      width: statusWidgetHeight * statusWidgetHeightFactor);
}

Widget _pacmanIconFromPainter({int mouthSize = pacmanCircleIncrements ~/ 4}) {
  return CustomPaint(
      size: const Size(statusWidgetHeight * statusWidgetHeightFactor,
          statusWidgetHeight * statusWidgetHeightFactor),
      painter: PacmanPainter(mouthSize: mouthSize));
}

const _pacmanRectStatusBarSize = statusWidgetHeight * statusWidgetHeightFactor;
final Rect _pacmanRectStatusBar = Rect.fromCenter(
    center: const Offset(
        _pacmanRectStatusBarSize / 2, _pacmanRectStatusBarSize / 2),
    width: _pacmanRectStatusBarSize.toDouble(),
    height: _pacmanRectStatusBarSize.toDouble());

class PacmanPainter extends CustomPainter {
  PacmanPainter({required this.mouthSize});

  int mouthSize;

  @override
  void paint(Canvas canvas, Size size) {
    double mouthWidth = mouthSize / pacmanCircleIncrements;
    mouthWidth = mouthWidth.clamp(0, 1);
    canvas.drawArc(
        _pacmanRectStatusBar,
        tau / 2 + tau * ((mouthWidth / 2) + 0.5),
        tau * (1 - mouthWidth),
        true,
        yellowPacmanPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

// ignore: unused_element
Widget _animatedPacmanIconDirect(PacmanGame game, int startValue) {
  return ValueListenableBuilder<int>(
      valueListenable: game.world.pacmans.pacmanDyingNotifier,
      builder: (BuildContext context, int value, Widget? child) {
        if (game.world.pacmans.pacmanDyingNotifier.value != startValue) {
          return _pacmanIconFromPainterDirect();
        } else {
          return pacmanIconCache[pacmanCircleIncrements ~/ 4];
        }
      });
}

Widget _pacmanIconFromPainterDirect(
    {int mouthSize = pacmanCircleIncrements ~/ 4}) {
  return CustomPaint(
      size: const Size(statusWidgetHeight * statusWidgetHeightFactor,
          statusWidgetHeight * statusWidgetHeightFactor),
      painter: PacmanPainterDirect(mouthSize: mouthSize));
}

class PacmanPainterDirect extends CustomPainter {
  PacmanPainterDirect({required this.mouthSize});

  int mouthSize;
  int startTime = DateTime.now().millisecondsSinceEpoch;

  @override
  void paint(Canvas canvas, Size size) {
    double mouthDouble = pacmanCircleIncrements ~/ 4 +
        pacmanCircleIncrements *
            3 ~/
            4 *
            (DateTime.now().millisecondsSinceEpoch - startTime) /
            kPacmanDeadResetTimeAnimationMillis;
    double mouthWidth = mouthDouble / pacmanCircleIncrements;
    mouthWidth = mouthWidth.clamp(0, 1);
    canvas.drawArc(_pacmanRectStatusBar, tau * ((mouthWidth / 2) + 0.5),
        tau * (1 - mouthWidth), true, yellowPacmanPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
