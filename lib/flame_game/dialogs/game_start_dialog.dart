import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../level_selection/levels.dart';
import '../../style/dialog.dart';
import '../../style/palette.dart';
import '../../utils/constants.dart';
import '../game_screen.dart';
import '../maze.dart';
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
    return popupDialog(
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
        mazeSelector(context, game),
        bottomRowWidget(
          children: game.levelStarted
              ? [
                  ValueListenableBuilder<bool>(
                      valueListenable: game.world.doingLevelResetFlourish,
                      builder:
                          (BuildContext context, bool value, Widget? child) {
                        return TextButton(
                            style: buttonStyle(
                                borderColor:
                                    game.world.doingLevelResetFlourish.value
                                        ? Palette.darkGrey
                                        : Palette.redWarning),
                            onPressed: () {
                              if (!game.world.doingLevelResetFlourish.value) {
                                game.overlays.remove(GameScreen.startDialogKey);
                                game.start();
                              }
                            },
                            child: Text('Reset', style: textStyleBody));
                      }),
                  TextButton(
                      style: buttonStyle(),
                      onPressed: () {
                        game.overlays.remove(GameScreen.startDialogKey);
                      },
                      child: Text('Resume', style: textStyleBody))
                ]
              : [
                  TextButton(
                      style: buttonStyle(),
                      onPressed: () {
                        game.overlays.remove(GameScreen.startDialogKey);
                        game.start();
                        //context.go('/');
                      },
                      child: Text('Play', style: textStyleBody)),
                ],
        )
      ],
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
                  ...List.generate(min(5, maxLevelToShow),
                      (index) => levelButtonSingle(context, game, index)),
                ],
              ),
              maxLevelToShow <= 5
                  ? const SizedBox.shrink()
                  : Row(
                      children: [
                        ...List.generate(
                            maxLevelToShow - 5,
                            (index) =>
                                levelButtonSingle(context, game, 5 + index)),
                      ],
                    )
            ],
          ),
        );
}

Widget levelButtonSingle(BuildContext context, PacmanGame game, int index) {
  return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
      child: ValueListenableBuilder<bool>(
          valueListenable: game.world.doingLevelResetFlourish,
          builder: (BuildContext context, bool value, Widget? child) {
            return TextButton(
                style: game.world.doingLevelResetFlourish.value
                    ? buttonStyle(small: true, borderColor: Palette.darkGrey)
                    : game.level.number == index + 1
                        ? buttonStyle(small: true)
                        : buttonStyle(small: true, borderColor: Palette.transp),
                onPressed: () {
                  if (!game.world.doingLevelResetFlourish.value) {
                    context.go('/session/${index + 1}');
                  }
                },
                child: Text('${index + 1}',
                    style:
                        game.world.playerProgress.levels.containsKey(index + 1)
                            ? textStyleBody
                            : textStyleBodyDull));
          }));
}

Widget mazeSelector(BuildContext context, PacmanGame game) {
  return game.world.playerProgress.maxLevelCompleted == 0 &&
          game.level.number == 1
      ? const SizedBox.shrink()
      : bodyWidget(
          child: Column(
            children: [
              Row(
                children: [
                  ...List.generate(
                      3, (index) => mazeButtonSingle(context, game, index)),
                ],
              ),
            ],
          ),
        );
}

Widget mazeButtonSingle(BuildContext context, PacmanGame game, int index) {
  return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
      child: ValueListenableBuilder<bool>(
          valueListenable: game.world.doingLevelResetFlourish,
          builder: (BuildContext context, bool value, Widget? child) {
            return TextButton(
                style: game.world.doingLevelResetFlourish.value
                    ? buttonStyle(small: true, borderColor: Palette.darkGrey)
                    : maze.mazeId == index
                        ? buttonStyle(small: true)
                        : buttonStyle(small: true, borderColor: Palette.transp),
                onPressed: () {
                  if (!game.world.doingLevelResetFlourish.value) {
                    maze.mazeId = index;
                    game.overlays.remove(GameScreen.startDialogKey);
                    game.start(mazeResize: true);
                  }
                },
                child: Text(["A", "B", "C"][index], style: textStyleBody));
          }));
}
