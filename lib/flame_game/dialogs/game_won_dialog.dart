import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../firebase/firebase_saves.dart';
import '../../level_selection/levels.dart';
import '../../router.dart';
import '../../style/dialog.dart';
import '../../style/palette.dart';
import '../game_screen.dart';
import '../maze.dart';
import '../pacman_game.dart';
import 'game_start_dialog.dart';

/// This dialog is shown when a level is won.
///
/// It shows what time the level was completed
/// and a comparison vs the leaderboard

class GameWonDialog extends StatelessWidget {
  const GameWonDialog({
    super.key,
    required this.level,
    required this.levelCompletedInMillis,
    required this.game,
  });

  /// The properties of the level that was just finished.
  final GameLevel level;

  final PacmanGame game;

  /// How many seconds that the level was completed in.
  final int levelCompletedInMillis;

  @override
  Widget build(BuildContext context) {
    final bool showNextButton = game.level.number + 1 <= Levels.maxLevel;
    return popupDialog(
      children: <Widget>[
        titleText(text: 'Complete'),
        bodyWidget(
          child: Text(
            _levelCompleteText(levelCompletedInMillis),
            style: textStyleBody,
          ),
        ),
        !FBase.firebaseOn || game.level.isTutorial
            ? const SizedBox.shrink()
            : bodyWidget(
                child: FutureBuilder<String>(
                    future: _scoreboardRankText(
                        levelNum: level.number,
                        levelCompletedInMillis: levelCompletedInMillis,
                        mazeId: maze.mazeId),
                    initialData: _scoreboardLoadingText(),
                    builder:
                        (BuildContext context, AsyncSnapshot<String> text) {
                      return Text(
                        text.data!,
                        style: textStyleBody,
                      );
                    }),
              ),
        levelSelector(context, game),
        mazeSelector(context, game),
        bottomRowWidget(
          children: <Widget>[
            TextButton(
                style: buttonStyle(
                    borderColor: showNextButton ? Palette.transp.color : null),
                onPressed: () {
                  game.overlays.remove(GameScreen.wonDialogKey);
                  game.resetAndStart();
                },
                child: const Text('Retry', style: textStyleBody)),
            !showNextButton
                ? const SizedBox.shrink()
                : TextButton(
                    style: buttonStyle(),
                    onPressed: () {
                      context.go(
                          '/?$levelUrlKey=${game.level.number + 1}&$mazeUrlKey=${maze.mazeId}');
                    },
                    child: const Text('Next', style: textStyleBody))
          ],
        ),
      ],
    );
  }
}

String _levelCompleteText(int levelCompletedInMillis) {
  return "Time: ${(levelCompletedInMillis / 1000).toStringAsFixed(1)} seconds";
}

String _scoreboardLoadingText() {
  return !FBase.firebaseOn ? "" : "Rank: Loading...";
}

Future<String> _scoreboardRankText(
    {required int levelNum,
    required int levelCompletedInMillis,
    required int mazeId}) async {
  if (!FBase.firebaseOn) {
    return "";
  }
  final double percentile = await fBase.firebasePercentile(
          levelNum: levelNum,
          levelCompletedInMillis: levelCompletedInMillis,
          mazeId: mazeId) *
      100.0;
  return "Rank: ${percentile == 0 ? "World Record" : "Top ${percentile.toStringAsFixed(0)}%"}";
}
