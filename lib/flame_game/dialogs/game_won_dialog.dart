import 'package:flutter/material.dart';

import '../../firebase/firebase_saves.dart';
import '../../level_selection/levels.dart';
import '../../style/dialog.dart';
import '../game_screen.dart';
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
    return popupDialog(
      children: [
        titleText(text: 'Complete'),
        bodyWidget(
          child: Text(
            _levelCompleteText(levelCompletedInMillis),
            style: textStyleBody,
          ),
        ),
        !Save.firebaseOn
            ? const SizedBox.shrink()
            : bodyWidget(
                child: FutureBuilder(
                    future: _scoreboardRankText(
                        level.number, levelCompletedInMillis),
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
          children: [
            TextButton(
                style: buttonStyle(),
                onPressed: () {
                  game.overlays.remove(GameScreen.wonDialogKey);
                  game.resetAndStart();
                },
                child: Text('Retry', style: textStyleBody)),
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
  return !Save.firebaseOn ? "" : "Rank: Loading...";
}

Future<String> _scoreboardRankText(
    int levelNum, int levelCompletedInMillis) async {
  double x = Save.firebaseOn
      ? (await save.firebasePercentile(levelNum, levelCompletedInMillis)) *
          100.0
      : 100.0;
  String y = !Save.firebaseOn
      ? ""
      : "Rank: ${x == 0 ? "World Record" : "Top ${x.toStringAsFixed(0)}%"}";
  return y;
}
