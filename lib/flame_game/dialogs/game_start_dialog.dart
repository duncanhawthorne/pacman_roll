import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../level_selection/levels.dart';
import '../../player_progress/player_progress.dart';
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
      children: <Widget>[
        rotatedTitle(),
        levelSelector(context, game),
        mazeSelector(context, game),
        bottomRowWidget(
          children: game.levelStarted
              ? <Widget>[
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
              : <Widget>[
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

Widget levelSelector(BuildContext context, PacmanGame game) {
  return ListenableBuilder(
      listenable: playerProgress,
      builder: (BuildContext context, _) {
        return levelSelectorReal(context, game);
      });
}

Widget levelSelectorReal(BuildContext context, PacmanGame game) {
  final int maxLevelToShowCache = maxLevelToShow(game);
  return bodyWidget(
    child: Column(
        spacing: 8,
        children: List<Widget>.generate(
            maxLevelToShowCache ~/ 5 + 1 + 1,
            (int rowIndex) => levelSelectorRow(
                context, game, maxLevelToShowCache, rowIndex))),
  );
}

Widget levelSelectorRow(BuildContext context, PacmanGame game,
    int maxLevelToShowCache, int rowIndex) {
  final bool showResetButton =
      playerProgress.maxLevelCompleted >= Levels.firstRealLevel;
  return Row(spacing: 4, children: <Widget>[
    showResetButton && rowIndex == 0
        ? resetWidget(context, game)
        : const SizedBox.shrink(),
    ...List<Widget>.generate(
        max(0, min(5, maxLevelToShowCache - rowIndex * 5 + 5)),
        (int colIndex) =>
            levelButtonSingle(context, game, rowIndex * 5 + colIndex + 1 - 5))
  ]);
}

Widget levelButtonSingle(BuildContext context, PacmanGame game, int levelNum) {
  if (levelNum < Levels.min || levelNum > Levels.max) {
    return const SizedBox.shrink();
  }
  final GameLevel level = levels.getLevel(levelNum);
  final int fixedMazeId = !level.isTutorial && maze.isTutorial
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
      child: Text(level.levelString,
          style: playerProgress.isComplete(levelNum)
              ? textStyleBody
              : textStyleBodyDull));
}

Widget mazeSelector(BuildContext context, PacmanGame game) {
  return ListenableBuilder(
      listenable: playerProgress,
      builder: (BuildContext context, _) {
        return mazeSelectorReal(context, game);
      });
}

Widget mazeSelectorReal(BuildContext context, PacmanGame game) {
  const bool enableMazeSelector = true;
  final int maxLevelToShowCache = maxLevelToShow(game);
  // ignore: dead_code
  final bool showText = false && maxLevelToShowCache <= 2;
  return !enableMazeSelector ||
          maxLevelToShowCache == 1 ||
          game.level.isTutorial
      ? const SizedBox.shrink()
      : bodyWidget(
          child: Column(
            children: <Widget>[
              Row(
                spacing: 4,
                children: <Widget>[
                  !showText
                      ? const SizedBox.shrink()
                      // ignore: dead_code
                      : const Padding(
                          padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                          child: Text('Maze:', style: textStyleBody),
                        ),
                  ...List<Widget>.generate(
                      3, (int index) => mazeButtonSingle(context, game, index)),
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
  return <int>[game.level.number, playerProgress.maxLevelCompleted + 1]
      .reduce(max)
      .clamp(Levels.min, Levels.max);
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

Widget resetWidget(BuildContext context, PacmanGame game) {
  return IconButton(
    onPressed: () => game.toggleOverlay(GameScreen.resetDialogKey),
    icon: const Icon(Icons.refresh, color: Palette.textColor),
  );
}
