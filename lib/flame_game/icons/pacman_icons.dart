import 'dart:math';

import 'package:flutter/material.dart';

import '../components/pacman.dart';
import '../game_screen.dart';
import '../pacman_game.dart';
import 'pacman_sprites.dart';

Widget animatedPacmanIcon(PacmanGame game, int index) {
  return ValueListenableBuilder<int>(
      valueListenable: game.world.pacmanDyingNotifier,
      builder: (BuildContext context, int value, Widget? child) {
        return TweenAnimationBuilder(
            tween: IntTween(
                begin: pacmanRenderFracIncrementsNumber ~/ 4,
                end: pacmanRenderFracIncrementsNumber ~/ 4 +
                    pacmanRenderFracIncrementsNumber *
                        3 ~/
                        4 *
                        min(
                            1,
                            max(0,
                                game.world.pacmanDyingNotifier.value - index))),
            duration: Duration(
                milliseconds: game.world.pacmanDyingNotifier.value <= index
                    ? 0 //when reset game
                    : kPacmanDeadResetTimeAnimationMillis),
            builder: (BuildContext context, int val, __) {
              return pacmanIconCache[val];
            });
      });
}

final pacmanIconCache = List.generate(pacmanRenderFracIncrementsNumber + 1,
    (int index) => _pacmanIconFromPainter(mouthInt: index));

// ignore: unused_element
Widget _pacmanIconFromFile(
    {int mouthInt = pacmanRenderFracIncrementsNumber ~/ 4}) {
  return Image.asset('assets/images/dash/$mouthInt.png',
      filterQuality: FilterQuality.none,
      height: statusWidgetHeight * statusWidgetHeightFactor,
      width: statusWidgetHeight * statusWidgetHeightFactor);
}

Widget _pacmanIconFromPainter(
    {int mouthInt = pacmanRenderFracIncrementsNumber ~/ 4}) {
  return CustomPaint(
      size: const Size(statusWidgetHeight * statusWidgetHeightFactor,
          statusWidgetHeight * statusWidgetHeightFactor),
      painter: MyPainter(mouthInt: mouthInt));
}

const _pacmanRectStatusBarSize = statusWidgetHeight * statusWidgetHeightFactor;
final Rect _pacmanRectStatusBar = Rect.fromCenter(
    center: const Offset(
        _pacmanRectStatusBarSize / 2, _pacmanRectStatusBarSize / 2),
    width: _pacmanRectStatusBarSize.toDouble(),
    height: _pacmanRectStatusBarSize.toDouble());

class MyPainter extends CustomPainter {
  MyPainter({required this.mouthInt});

  int mouthInt;

  @override
  void paint(Canvas canvas, Size size) {
    double mouthWidth = mouthInt / pacmanRenderFracIncrementsNumber;
    mouthWidth = max(0, min(1, mouthWidth));
    canvas.drawArc(_pacmanRectStatusBar, 2 * pi * ((mouthWidth / 2) + 0.5),
        2 * pi * (1 - mouthWidth), true, yellowPacmanPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

// ignore: unused_element
Widget _animatedPacmanIconDirect(PacmanGame game, int startValue) {
  return ValueListenableBuilder<int>(
      valueListenable: game.world.pacmanDyingNotifier,
      builder: (BuildContext context, int value, Widget? child) {
        if (game.world.pacmanDyingNotifier.value != startValue) {
          return _pacmanIconFromPainterDirect();
        } else {
          return pacmanIconCache[pacmanRenderFracIncrementsNumber ~/ 4];
        }
      });
}

Widget _pacmanIconFromPainterDirect(
    {int mouthInt = pacmanRenderFracIncrementsNumber ~/ 4}) {
  return CustomPaint(
      size: const Size(statusWidgetHeight * statusWidgetHeightFactor,
          statusWidgetHeight * statusWidgetHeightFactor),
      painter: MyPainterDirect(mouthInt: mouthInt));
}

class MyPainterDirect extends CustomPainter {
  MyPainterDirect({required this.mouthInt});

  int mouthInt;
  int startTime = DateTime.now().millisecondsSinceEpoch;

  @override
  void paint(Canvas canvas, Size size) {
    double mouthDouble = pacmanRenderFracIncrementsNumber ~/ 4 +
        pacmanRenderFracIncrementsNumber *
            3 ~/
            4 *
            (DateTime.now().millisecondsSinceEpoch - startTime) /
            kPacmanDeadResetTimeAnimationMillis;
    double mouthWidth = mouthDouble / pacmanRenderFracIncrementsNumber;
    mouthWidth = max(0, min(1, mouthWidth));
    canvas.drawArc(_pacmanRectStatusBar, 2 * pi * ((mouthWidth / 2) + 0.5),
        2 * pi * (1 - mouthWidth), true, yellowPacmanPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
