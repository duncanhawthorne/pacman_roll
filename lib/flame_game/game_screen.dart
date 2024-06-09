import 'dart:math';

import 'package:elapsed_time_display/elapsed_time_display.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../style/palette.dart';
import 'components/pacman.dart';
import 'components/pacman_sprites.dart';
import 'game_lose_dialog.dart';
import 'game_won_dialog.dart';
import 'pacman_game.dart';

/// This widget defines the properties of the game screen.
///
/// It mostly sets up the overlays (widgets shown on top of the Flame game) and
/// the gets the [AudioController] from the context and passes it in to the
/// [PacmanGame] class so that it can play audio.

const double _factor = 0.75;

class GameScreen extends StatelessWidget {
  const GameScreen({required this.level, super.key});

  final GameLevel level;

  static const String loseDialogKey = 'lose_dialog';
  static const String wonDialogKey = 'won_dialog';
  static const String backButtonKey = 'back_button';
  static const String statusOverlayKey = 'status_overlay';

  @override
  Widget build(BuildContext context) {
    context.watch<Palette>();
    final audioController = context.read<AudioController>();
    final palette = context.read<Palette>();
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: GameWidget<PacmanGame>(
          key: const Key('play session'),
          game: PacmanGame(
            level: level,
            playerProgress: context.read<PlayerProgress>(),
            audioController: audioController,
            palette: palette,
          ),
          overlayBuilderMap: {
            backButtonKey: (BuildContext context, PacmanGame game) {
              return backButtonWidget(context, game);
            },
            statusOverlayKey: (BuildContext context, PacmanGame game) {
              return statusOverlayWidget(context, game);
            },
            loseDialogKey: (BuildContext context, PacmanGame game) {
              return GameLoseDialog(
                level: level,
              );
            },
            wonDialogKey: (BuildContext context, PacmanGame game) {
              return GameWonDialog(
                  level: level,
                  levelCompletedIn: game.stopwatchSeconds,
                  game: game);
            },
          },
        ),
      ),
    );
  }
}

Widget backButtonWidget(BuildContext context, PacmanGame game) {
  return Positioned(
    top: 20,
    left: 30,
    child: NesButton(
      type: NesButtonType.normal,
      onPressed: () {
        GoRouter.of(context).go("/");
      },
      child: NesIcon(
          iconData: NesIcons.leftArrowIndicator, size: const Size(15, 15)),
    ),
  );
}

const _statusWidgetHeight = 30;

Widget statusOverlayWidget(BuildContext context, PacmanGame game) {
  return Positioned(
    top: 27,
    right: 30,
    child: Container(
      height: _statusWidgetHeight.toDouble(),
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: game.world.numberOfDeathsNotifier,
            builder: (BuildContext context, int value, Widget? child) {
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(
                      3 - game.world.numberOfDeathsNotifier.value,
                      (index) => Padding(
                          padding: const EdgeInsets.fromLTRB(
                              4 * _factor, 0, 4 * _factor, 0),
                          child: Transform.rotate(
                              angle: 2 * pi / 2,
                              child: index == 0
                                  ? _animatedPacmanIcon(game,
                                      game.world.pacmanDyingNotifier.value)
                                  : _pacmanIconCache[
                                      pacmanRenderFracIncrementsNumber ~/
                                          4]))));
            },
          ),
          const SizedBox(width: 20 * _factor, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 3, 0, 0),
            child: ElapsedTimeDisplay(
              startTime: DateTime.now(), //actually ignored
              interval: const Duration(milliseconds: 100),
              style: const TextStyle(
                  fontSize: 18 * _factor,
                  color: Colors.white,
                  fontFamily: 'Press Start 2P'),
              formatter: (elapsedTime) {
                return game.stopwatchSeconds.toStringAsFixed(1).padLeft(4, " ");
              },
            ),
          ),
        ],
      ),
    ),
  );
}

// ignore: unused_element
Widget _animatedPacmanIcon(PacmanGame game, int startValue) {
  return ValueListenableBuilder<int>(
      valueListenable: game.world.pacmanDyingNotifier,
      builder: (BuildContext context, int value, Widget? child) {
        int currentValue = game.world.pacmanDyingNotifier.value;
        return TweenAnimationBuilder(
            tween: IntTween(
                begin: pacmanRenderFracIncrementsNumber ~/ 4,
                end: pacmanRenderFracIncrementsNumber ~/ 4 +
                    pacmanRenderFracIncrementsNumber *
                        3 ~/
                        4 *
                        (currentValue - startValue)),
            duration: Duration(
                milliseconds: currentValue == startValue
                    ? 0
                    : kPacmanDeadResetTimeAnimationMillis),
            builder: (BuildContext context, int val, __) {
              return _pacmanIconCache[val];
            });
      });
}

final _pacmanIconCache = List.generate(pacmanRenderFracIncrementsNumber + 1,
    (int index) => _pacmanIconFromPainter(mouthInt: index));

// ignore: unused_element
Widget _pacmanIconFromFile(
    {int mouthInt = pacmanRenderFracIncrementsNumber ~/ 4}) {
  return Image.asset('assets/images/dash/$mouthInt.png',
      filterQuality: FilterQuality.none,
      height: _statusWidgetHeight * _factor,
      width: _statusWidgetHeight * _factor);
}

Widget _pacmanIconFromPainter(
    {int mouthInt = pacmanRenderFracIncrementsNumber ~/ 4}) {
  return CustomPaint(
      size: const Size(
          _statusWidgetHeight * _factor, _statusWidgetHeight * _factor),
      painter: MyPainter(mouthInt: mouthInt));
}

const _pacmanRectStatusBarSize = _statusWidgetHeight * _factor;
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
          return _pacmanIconCache[pacmanRenderFracIncrementsNumber ~/ 4];
        }
      });
}

Widget _pacmanIconFromPainterDirect(
    {int mouthInt = pacmanRenderFracIncrementsNumber ~/ 4}) {
  return CustomPaint(
      size: const Size(
          _statusWidgetHeight * _factor, _statusWidgetHeight * _factor),
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
