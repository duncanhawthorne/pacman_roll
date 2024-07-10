import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../level_selection/levels.dart';
import '../../style/dialog.dart';
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
          titleWidget(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
              child: Transform.rotate(
                angle: -0.1,
                child: Text(appTitle,
                    style: textStyleHeading, textAlign: TextAlign.center),
              ),
            ),
          ),
          levelSelector(context, game),
          bottomRowWidget(
            children: game.levelStarted
                ? [
                    TextButton(
                        style: buttonStyleWarning,
                        onPressed: () {
                          if (!game.world.doingLevelResetFlourish) {
                            game.overlays.remove(GameScreen.startDialogKey);
                            game.start();
                          }
                        },
                        child: Text('Reset', style: textStyleBody)),
                    TextButton(
                        style: buttonStyleNormal,
                        onPressed: () {
                          game.overlays.remove(GameScreen.startDialogKey);
                        },
                        child: Text('Resume', style: textStyleBody))
                  ]
                : [
                    TextButton(
                        style: buttonStyleNormal,
                        onPressed: () {
                          game.overlays.remove(GameScreen.startDialogKey);
                          game.start();
                          //context.go('/');
                        },
                        child: Text('Play', style: textStyleBody)),
                  ],
          )
        ],
      ),
    );
  }
}

Widget levelSelector(BuildContext context, PacmanGame game) {
  int maxLevelToShow = min(gameLevels.length,
      max(game.level.number, game.world.playerProgress.maxLevelCompleted + 1));
  bool showText = maxLevelToShow <= 2;
  return game.world.playerProgress.maxLevelCompleted == 0 &&
          game.level.number == 1
      ? const SizedBox.shrink()
      : bodyWidget(
          child: Column(
            children: [
              Row(
                children: [
                  !showText
                      ? const SizedBox.shrink()
                      : Text('Level:', style: textStyleBody),
                  !showText
                      ? const SizedBox.shrink()
                      : const SizedBox(width: 10),
                  ...List.generate(
                      min(5, maxLevelToShow),
                      (index) => Padding(
                            padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                            child: TextButton(
                                style: game.level.number == index + 1
                                    ? buttonStyleSmallActive
                                    : buttonStyleSmallPassive,
                                onPressed: () {
                                  if (!game.world.doingLevelResetFlourish) {
                                    context.go('/session/${index + 1}');
                                  }
                                },
                                child: Text('${index + 1}',
                                    style: game.world.playerProgress.levels
                                            .containsKey(index + 1)
                                        ? textStyleBody
                                        : textStyleBodyDull)),
                          )),
                ],
              ),
              maxLevelToShow <= 5
                  ? const SizedBox.shrink()
                  : Row(
                      children: [
                        ...List.generate(
                            maxLevelToShow - 5,
                            (index) => Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(2, 0, 2, 0),
                                  child: TextButton(
                                      style: game.level.number == index + 5 + 1
                                          ? buttonStyleSmallActive
                                          : buttonStyleSmallPassive,
                                      onPressed: () {
                                        if (!game
                                            .world.doingLevelResetFlourish) {
                                          context
                                              .go('/session/${index + 5 + 1}');
                                        }
                                      },
                                      child: Text('${index + 5 + 1}',
                                          style: game
                                                  .world.playerProgress.levels
                                                  .containsKey(index + 5 + 1)
                                              ? textStyleBody
                                              : textStyleBodyDull)),
                                )),
                      ],
                    )
            ],
          ),
        );
}
