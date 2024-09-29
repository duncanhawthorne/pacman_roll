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
  return bodyWidget(
    child: Column(
        spacing: 8,
        children: List.generate(
            maxLevelToShowCache ~/ 5 + 1,
            (rowIndex) => levelSelectorRow(
                context, game, maxLevelToShowCache, rowIndex))),
  );
}

Widget levelSelectorRow(BuildContext context, PacmanGame game,
    int maxLevelToShowCache, int rowIndex) {
  bool showTutorialButton = true;
  return Row(spacing: 4, children: [
    showTutorialButton && rowIndex == 0
        ? levelButtonSingle(context, game, 0)
        : const SizedBox.shrink(),
    ...List.generate(
        min(5, maxLevelToShowCache - rowIndex * 5),
        (colIndex) =>
            levelButtonSingle(context, game, rowIndex * 5 + colIndex + 1))
  ]);
}

Widget levelButtonSingle(BuildContext context, PacmanGame game, int levelNum) {
  GameLevel level = levels.getLevel(levelNum);
  int fixedMazeId = !level.isTutorial && maze.isTutorial
      ? Maze.defaultMazeId
      : level.isTutorial && !maze.isTutorial
          ? Maze.tutorialMazeId
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
          level.isTutorial
              ? (maxLevelToShow(game) == Levels.tutorialLevelNum
                  ? "Tutorial"
                  : "T")
              : '$levelNum',
          style: game.world.playerProgress.ppLevels.containsKey(levelNum)
              ? textStyleBody
              : textStyleBodyDull));
}

Widget mazeSelector(BuildContext context, PacmanGame game) {
  const bool enableMazeSelector = true;
  int maxLevelToShowCache = maxLevelToShow(game);
  // ignore: dead_code
  bool showText = false && maxLevelToShowCache <= 2;
  return !enableMazeSelector ||
          maxLevelToShowCache == 1 ||
          game.level.isTutorial
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
    maze.isTutorial || maze.isDefault
        ? Levels.tutorialLevelNum - 1 //no effect to max
        : Levels.firstRealLevel + 1, //at least something
    game.world.playerProgress.maxLevelCompleted + 1
  ].reduce(max).clamp(0, Levels.max);
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
