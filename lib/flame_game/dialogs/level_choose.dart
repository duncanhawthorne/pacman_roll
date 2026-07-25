import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../level_selection/levels.dart';
import '../../router.dart';
import '../../style/dialog.dart';
import '../../style/palette.dart';
import '../../utils/constants.dart';
import '../game_screen.dart';
import '../maze/maze.dart';
import '../custom_game.dart';

/// This dialog is shown before starting the game.

/// Main menu and level/maze selection dialog shown before a game session begins.
class LevelChooseDialog extends StatelessWidget {
  const LevelChooseDialog({super.key, required this.level, required this.game});

  /// The level configuration for the current game session.
  final GameLevel level;

  final CustomGame game;

  @override
  Widget build(BuildContext context) {
    assert(!(game.playState == PlayState.playbackMode));
    return popupDialog(
      children: <Widget>[
        rotatedTitle(),
        ...<Widget>[levelSelector(context, game), mazeSelector(context, game)],
        bottomRowWidget(
          children: game.lifecycle.stopwatchStarted
              ? <Widget>[
                  TextButton(
                    style: buttonStyle(borderColor: Palette.warning.color),
                    onPressed: () {
                      game.overlays.remove(GameScreen.startDialogKey);
                      game
                        ..resetAndStart()
                        ..playState = PlayState.gaming;
                    },
                    child: const Text('Reset', style: textStyleBody),
                  ),
                  TextButton(
                    style: buttonStyle(),
                    onPressed: () {
                      game.overlays.remove(GameScreen.startDialogKey);
                    },
                    child: const Text('Resume', style: textStyleBody),
                  ),
                ]
              : <Widget>[
                  TextButton(
                    style: buttonStyle(),
                    onPressed: () {
                      game.overlays.remove(GameScreen.startDialogKey);
                      game.playState = PlayState.gaming;
                    },
                    child: const Text('Play', style: textStyleBody),
                  ),
                ],
        ),
      ],
    );
  }
}

/// Widget that allows the user to select a game level.
Widget levelSelector(BuildContext context, CustomGame game) {
  return ListenableBuilder(
    listenable: game.playerProgress,
    builder: (BuildContext context, _) {
      return levelSelectorReal(context, game);
    },
  );
}

const int _cols = 5;
const int _negativeRows = 1;

Widget levelSelectorReal(BuildContext context, CustomGame game) {
  final int maxLevelToShowCache = _maxLevelToShow(game);
  return bodyWidget(
    child: Column(
      spacing: 8,
      children: List<Widget>.generate(
        maxLevelToShowCache ~/ _cols + 1 + _negativeRows,
        (int rowIndex) =>
            levelSelectorRow(context, game, maxLevelToShowCache, rowIndex),
      ),
    ),
  );
}

Widget levelSelectorRow(
  BuildContext context,
  CustomGame game,
  int maxLevelToShowCache,
  int rowIndex,
) {
  final bool showResetButton = true;
  return Row(
    spacing: 4,
    children: <Widget>[
      showResetButton && rowIndex == 0
          ? resetWidget(context, game)
          : const SizedBox.shrink(),
      ...List<Widget>.generate(
        max(
          0,
          min(
            _cols,
            maxLevelToShowCache - rowIndex * _cols + _cols * _negativeRows,
          ),
        ),
        (int colIndex) => levelButtonSingle(
          context,
          game,
          rowIndex * _cols + colIndex + 1 - _cols * _negativeRows,
        ),
      ),
    ],
  );
}

Widget levelButtonSingle(BuildContext context, CustomGame game, int levelNum) {
  if (levelNum < Levels.minLevel || levelNum > Levels.maxLevel) {
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
        '/?$levelUrlKey=$levelNum&$mazeUrlKey=${mazeNames[fixedMazeId]}',
      );
    },
    child: Text(
      level.levelString,
      style: game.playerProgress.isComplete(levelNum)
          ? textStyleBody
          : textStyleBodyDull,
    ),
  );
}

/// Widget that allows the user to select a maze layout.
Widget mazeSelector(BuildContext context, CustomGame game) {
  return ListenableBuilder(
    listenable: game.playerProgress,
    builder: (BuildContext context, _) {
      return mazeSelectorReal(context, game);
    },
  );
}

Widget mazeSelectorReal(BuildContext context, CustomGame game) {
  const bool enableMazeSelector = true;
  final int maxLevelToShowCache = _maxLevelToShow(game);
  return !enableMazeSelector ||
          maxLevelToShowCache == 1 ||
          game.level.isTutorial
      ? const SizedBox.shrink()
      : bodyWidget(
          child: Column(
            children: <Widget>[
              Row(
                spacing: 4,
                children: List<Widget>.generate(
                  3,
                  (int index) => mazeButtonSingle(context, game, index),
                ),
              ),
            ],
          ),
        );
}

Widget mazeButtonSingle(BuildContext context, CustomGame game, int mazeId) {
  return TextButton(
    style: maze.mazeId == mazeId
        ? buttonStyle(small: true)
        : buttonStyle(small: true, borderColor: Palette.transp.color),
    onPressed: () {
      if (mazeId != maze.mazeId) {
        context.go(
          '/?$levelUrlKey=${game.level.number}&$mazeUrlKey=${mazeNames[mazeId]}',
        );
      }
    },
    child: Text(mazeNames[mazeId] ?? "X", style: textStyleBody),
  );
}

int _maxLevelToShow(CustomGame game) {
  return max(1, levelAfterPlaybackScreen(game));
}

int levelAfterPlaybackScreen(CustomGame game) {
  return <int>[
    game.level.number,
    game.playerProgress.maxLevelCompleted + 1,
  ].reduce(max).clamp(Levels.minLevel, Levels.maxLevel);
}

Widget rotatedTitle() {
  return titleWidget(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Transform.rotate(
        angle: -0.1,
        child: const Text(
          appTitle,
          style: textStyleHeading,
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

Widget resetWidget(BuildContext context, CustomGame game) {
  return IconButton(
    onPressed: () => game.dialogs.toggle(GameScreen.resetDialogKey),
    icon: const Icon(Icons.refresh, color: Palette.textColor),
  );
}
