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
                        game.resetAndStart();
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

const double width = 40; //70;
Widget levelSelector(BuildContext context, PacmanGame game) {
  int maxLevelToShowCache = maxLevelToShow(game);
  bool showText = false && maxLevelToShowCache <= 2;
  return bodyWidget(
    child: Column(
      children: [
        Row(
          children: [
            !showText
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
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
  return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
      child: TextButton(
          style: game.level.number == levelNum
              ? buttonStyle(small: true)
              : buttonStyle(small: true, borderColor: Palette.transp),
          onPressed: () {
            context.go(
                '/?$levelUrlKey=$levelNum&$mazeUrlKey=${mazeNames[fixedMazeId]}');
          },
          child: Text(
              isTutorialLevel(levelSelect(levelNum))
                  ? (maxLevelToShow(game) == tutorialLevelNum
                      ? "Tutorial"
                      : "T")
                  : '$levelNum',
              style: game.world.playerProgress.levels.containsKey(levelNum)
                  ? textStyleBody
                  : textStyleBodyDull)));
}

Widget mazeSelector(BuildContext context, PacmanGame game) {
  int maxLevelToShowCache = maxLevelToShow(game);
  bool showText = false && maxLevelToShowCache <= 2;
  return maxLevelToShowCache == 1 ||
          isTutorialLevel(levelSelect(game.level.number))
      ? const SizedBox.shrink()
      : bodyWidget(
          child: Column(
            children: [
              Row(
                children: [
                  !showText
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
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
  return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
      child: TextButton(
          style: maze.mazeId == mazeId
              ? buttonStyle(small: true)
              : buttonStyle(small: true, borderColor: Palette.transp),
          onPressed: () {
            if (mazeId != maze.mazeId) {
              context.go(
                  '/?$levelUrlKey=${game.level.number}&$mazeUrlKey=${mazeNames[mazeId]}');
            }
          },
          child: Text(mazeNames[mazeId] ?? "X", style: textStyleBody)));
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
