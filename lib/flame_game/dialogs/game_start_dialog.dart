import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../level_selection/levels.dart';
import '../../router.dart';
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
                  TextButton(
                      style: buttonStyle(borderColor: Palette.redWarning),
                      onPressed: () {
                        game.overlays.remove(GameScreen.startDialogKey);
                        game.start();
                      },
                      child: Text('Reset', style: textStyleBody)),
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
                      },
                      child: Text('Play', style: textStyleBody)),
                ],
        )
      ],
    );
  }
}

Widget levelSelector(BuildContext context, PacmanGame game) {
  int maxLevelToShowCache = maxLevelToShow(game);
  bool showText = maxLevelToShowCache <= 2;
  return maxLevelToShowCache == 1
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
                  ...List.generate(min(5, maxLevelToShowCache),
                      (index) => levelButtonSingle(context, game, index)),
                ],
              ),
              maxLevelToShowCache <= 5
                  ? const SizedBox.shrink()
                  : Row(
                      children: [
                        ...List.generate(
                            maxLevelToShowCache - 5,
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
      child: TextButton(
          style: game.level.number == index + 1
              ? buttonStyle(small: true)
              : buttonStyle(small: true, borderColor: Palette.transp),
          onPressed: () {
            context.go(
                '/?$levelUrl=${index + 1}&$mapUrl=${mazeNames[maze.mazeId]}');
          },
          child: Text('${index + 1}',
              style: game.world.playerProgress.levels.containsKey(index + 1)
                  ? textStyleBody
                  : textStyleBodyDull)));
}

Widget mazeSelector(BuildContext context, PacmanGame game) {
  int maxLevelToShowCache = maxLevelToShow(game);
  bool showText = maxLevelToShowCache <= 2;
  return maxLevelToShowCache == 1
      ? const SizedBox.shrink()
      : bodyWidget(
          child: Column(
            children: [
              Row(
                children: [
                  !showText
                      ? const SizedBox.shrink()
                      : Text('Maze:', style: textStyleBody),
                  !showText
                      ? const SizedBox.shrink()
                      : const SizedBox(width: 10),
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
      child: TextButton(
          style: maze.mazeId == index
              ? buttonStyle(small: true)
              : buttonStyle(small: true, borderColor: Palette.transp),
          onPressed: () {
            if (index != maze.mazeId) {
              context.go(
                  '/?$levelUrl=${game.level.number}&$mapUrl=${mazeNames[index]}');
            }
          },
          child: Text(mazeNames[index], style: textStyleBody)));
}

int maxLevelToShow(PacmanGame game) {
  return min(
      gameLevels.length,
      max(max(game.level.number, maze.mazeId == 0 ? 1 : 2),
          game.world.playerProgress.maxLevelCompleted + 1));
}
