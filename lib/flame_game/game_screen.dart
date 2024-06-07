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

Widget statusOverlayWidget(BuildContext context, PacmanGame game) {
  return Positioned(
    top: 27,
    right: 30,
    child: Container(
      height: 30,
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
                                  : _pacmanIconCache[8]))));
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

Widget _animatedPacmanIcon(PacmanGame game, int startValue) {
  return ValueListenableBuilder<int>(
      valueListenable: game.world.pacmanDyingNotifier,
      builder: (BuildContext context, int value, Widget? child) {
        int currentValue = game.world.pacmanDyingNotifier.value;
        return TweenAnimationBuilder(
            tween:
                IntTween(begin: 8, end: 8 + 24 * (currentValue - startValue)),
            duration: Duration(
                milliseconds: currentValue == startValue
                    ? 0
                    : kPacmanDeadResetTimeAnimationMillis),
            builder: (BuildContext context, int val, __) {
              return _pacmanIconCache[val];
            });
      });
}

final _pacmanIconCache =
    List.generate(33, (int index) => _pacmanIconFromPainter(mouthInt: index));

// ignore: unused_element
Widget _pacmanIconFromFile({int mouthInt = 8}) {
  return Image.asset('assets/images/dash/$mouthInt.png',
      filterQuality: FilterQuality.none,
      height: 30 * _factor,
      width: 30 * _factor);
}

Widget _pacmanIconFromPainter({int mouthInt = 8}) {
  return CustomPaint(
      size: const Size(30 * _factor, 30 * _factor),
      painter: MyPainter(mouthInt: mouthInt));
}

const _pacmanRectSize = 30 * _factor;
final Rect _pacmanRect = Rect.fromCenter(
    center: const Offset(_pacmanRectSize / 2, _pacmanRectSize / 2),
    width: _pacmanRectSize.toDouble(),
    height: _pacmanRectSize.toDouble());

class MyPainter extends CustomPainter {
  MyPainter({required this.mouthInt});

  int mouthInt;

  @override
  void paint(Canvas canvas, Size size) {
    double mouthWidth = mouthInt / pacmanRenderFracIncrementsNumber;
    mouthWidth = max(0, min(1, mouthWidth));
    canvas.drawArc(_pacmanRect, 2 * pi * ((mouthWidth / 2) + 0.5),
        2 * pi * (1 - mouthWidth), true, yellowPacmanPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
