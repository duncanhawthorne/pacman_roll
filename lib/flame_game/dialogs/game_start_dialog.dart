import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../level_selection/levels.dart';
import '../../style/palette.dart';
import '../../utils/constants.dart';
import '../game_screen.dart';
import '../pacman_game.dart';

/// This dialog is shown before starting the game.

class StartDialog extends StatelessWidget {
  const StartDialog({
    super.key,
    required this.level,
    required this.game,
  });

  /// The properties of the level that was just finished.
  final GameLevel level;

  final PacmanGame game;

  @override
  Widget build(BuildContext context) {
    return pacmanDialog(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16 + 16, 0, 16 + 8),
            child: Transform.rotate(
              angle: -0.1,
              child: Text(appTitle,
                  style: textStyleHeading, textAlign: TextAlign.center),
            ),
          ),
          levelSelector(context, game),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
            child: game.levelStarted
                ? Row(
                    children: [
                      TextButton(
                          style: buttonStyleWarning,
                          onPressed: () {
                            if (!game.world.doingLevelResetFlourish) {
                              game.overlays.remove(GameScreen.startDialogKey);
                              game.start();
                            }
                          },
                          child: Text('Reset', style: textStyleBody)),
                      const SizedBox(width: 10),
                      TextButton(
                          style: buttonStyleNormal,
                          onPressed: () {
                            game.overlays.remove(GameScreen.startDialogKey);
                          },
                          child: Text('Resume', style: textStyleBody))
                    ],
                  )
                : TextButton(
                    style: buttonStyleNormal,
                    onPressed: () {
                      game.overlays.remove(GameScreen.startDialogKey);
                      game.start();
                      //context.go('/');
                    },
                    child: Text('Play', style: textStyleBody)),
          ),
        ],
      ),
    );
  }
}

Widget levelSelector(BuildContext context, PacmanGame game) {
  bool showText = game.level.number <= 2;
  return game.world.playerProgress.levels.isEmpty && game.level.number == 1
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Row(
            children: [
              !showText
                  ? const SizedBox.shrink()
                  : Text('Level:', style: textStyleBody),
              !showText ? const SizedBox.shrink() : const SizedBox(width: 10),
              ...List.generate(
                  min(
                      gameLevels.length,
                      max(game.level.number,
                          game.world.playerProgress.levels.length + 1)),
                  (index) => Padding(
                        padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                        child: TextButton(
                            style: game.level.number == index + 1
                                ? buttonStyleSmallActive
                                : buttonStyleSmallPassive,
                            onPressed: () {
                              context.go('/session/${index + 1}');
                            },
                            child: Text('${index + 1}', style: textStyleBody)),
                      )),
            ],
          ),
        );
}

Widget pacmanDialog({required Widget child}) {
  return Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.all(75.0),
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Palette.borderColor.color, width: 3),
              borderRadius: BorderRadius.circular(10),
              color: Palette.playSessionBackground.color),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(40.0, 4, 40, 4), child: child),
        ),
      ),
    ),
  );
}

Widget titleText({required String text}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
    child: Text(text, style: textStyleHeading, textAlign: TextAlign.center),
  );
}
