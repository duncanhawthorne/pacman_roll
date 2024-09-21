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
        rotatedTitle(),
        levelSelector(context, game),
        mazeSelector(context, game),
        bottomRowWidget(
          children: game.levelStarted
              ? [
                  TextButton(
                      style: buttonStyle(borderColor: Palette.warning.color),
                      onPressed: () {
                        game.overlays.remove(GameScreen.startDialogKey);
                        game.resetAndStart();
                      },
                      child: const Text('Reset', style: textStyleBody)),
                  TextButton(
                      style: buttonStyle(),
                      onPressed: () {
                        game.overlays.remove(GameScreen.startDialogKey);
                      },
                      child: const Text('Resume', style: textStyleBody))
                ]
              : [
                  TextButton(
                      style: buttonStyle(),
                      onPressed: () {
                        game.overlays.remove(GameScreen.startDialogKey);
                        game.start();
                      },
                      child: const Text('Play', style: textStyleBody)),
                ],
        )
      ],
    );
  }
}

const double width = 40; //70;
Widget levelSelector(BuildContext context, PacmanGame game) {
  int maxLevelToShowCache = maxLevelToShow(game);
  // ignore: dead_code
  bool showText = false && maxLevelToShowCache <= 2;
  return bodyWidget(
    child: Column(
      children: [
        Row(
          spacing: 4,
          children: [
            !showText
                ? const SizedBox.shrink()
                // ignore: dead_code
                : const Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                    child: Text('Level:', style: textStyleBody),
                  ),
            levelButtonSingle(context, game, 0),
            ...List.generate(min(5, maxLevelToShowCache),
                (index) => levelButtonSingle(context, game, index + 1)),
          ],
        ),
        maxLevelToShowCache <= 5
            ? const SizedBox.shrink()
            : Row(
                spacing: 4,
                children: [
                  ...List.generate(
                      maxLevelToShowCache - 5,
                      (index) =>
                          levelButtonSingle(context, game, 5 + index + 1)),
                ],
              )
      ],
    ),
  );
}

Widget levelButtonSingle(BuildContext context, PacmanGame game, int levelNum) {
  int fixedMazeId = !isTutorialLevel(levelSelect(levelNum)) &&
          isTutorialMaze(maze.mazeId)
      ? defaultMazeId
      : isTutorialLevel(levelSelect(levelNum)) && !isTutorialMaze(maze.mazeId)
          ? tutorialMazeId
          : maze.mazeId;
  return TextButton(
      style: game.level.number == levelNum
          ? buttonStyle(small: true)
          : buttonStyle(small: true, borderColor: Palette.transp.color),
      onPressed: () {
        context.go(
            '/?$levelUrlKey=$levelNum&$mazeUrlKey=${mazeNames[fixedMazeId]}');
      },
      child: Text(
          isTutorialLevel(levelSelect(levelNum))
              ? (maxLevelToShow(game) == tutorialLevelNum ? "Tutorial" : "T")
              : '$levelNum',
          style: game.world.playerProgress.levels.containsKey(levelNum)
              ? textStyleBody
              : textStyleBodyDull));
}

Widget mazeSelector(BuildContext context, PacmanGame game) {
  int maxLevelToShowCache = maxLevelToShow(game);
  // ignore: dead_code
  bool showText = false && maxLevelToShowCache <= 2;
  return maxLevelToShowCache == 1 ||
          isTutorialLevel(levelSelect(game.level.number))
      ? const SizedBox.shrink()
      : bodyWidget(
          child: Column(
            children: [
              Row(
                spacing: 4,
                children: [
                  !showText
                      ? const SizedBox.shrink()
                      // ignore: dead_code
                      : const Padding(
                          padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                          child: Text('Maze:', style: textStyleBody),
                        ),
                  ...List.generate(
                      3, (index) => mazeButtonSingle(context, game, index)),
                ],
              ),
            ],
          ),
        );
}

Widget mazeButtonSingle(BuildContext context, PacmanGame game, int mazeId) {
  return TextButton(
      style: maze.mazeId == mazeId
          ? buttonStyle(small: true)
          : buttonStyle(small: true, borderColor: Palette.transp.color),
      onPressed: () {
        if (mazeId != maze.mazeId) {
          context.go(
              '/?$levelUrlKey=${game.level.number}&$mazeUrlKey=${mazeNames[mazeId]}');
        }
      },
      child: Text(mazeNames[mazeId] ?? "X", style: textStyleBody));
}

int maxLevelToShow(PacmanGame game) {
  return [
    game.level.number,
    isTutorialMaze(maze.mazeId) || maze.mazeId == tutorialMazeId + 1
        ? tutorialLevelNum - 1
        : defaultLevelNum + 1,
    game.world.playerProgress.maxLevelCompleted + 1
  ].reduce(max).clamp(0, maxLevel());
}

Widget rotatedTitle() {
  return titleWidget(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Transform.rotate(
        angle: -0.1,
        child: const Text(appTitle,
            style: textStyleHeading, textAlign: TextAlign.center),
      ),
    ),
  );
}
