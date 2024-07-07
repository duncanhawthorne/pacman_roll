import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../firebase/firebase_saves.dart';
import '../../level_selection/levels.dart';
import '../../style/palette.dart';
import '../game_screen.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'start_dialog.dart';

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
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(75.0),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: Palette.borderColor.color, width: 3),
                borderRadius: BorderRadius.circular(10),
                color: Palette.playSessionBackground.color),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40.0, 4, 40, 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                    child: Text('Complete',
                        style: headingTextStyle, textAlign: TextAlign.center),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                    child: Text(
                      _levelCompleteText(levelCompletedInMillis),
                      style: bodyTextStyle,
                    ),
                  ),
                  !Save.firebaseOn
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                          child: FutureBuilder(
                              future: _scoreboardRankText(
                                  level.number, levelCompletedInMillis),
                              initialData: _scoreboardLoadingText(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<String> text) {
                                return Text(
                                  text.data!,
                                  style: bodyTextStyle,
                                );
                              }),
                        ),
                  levelSelector(context, game),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                    child: TextButton(
                        style: buttonStyle,
                        onPressed: () {
                          if (overlayMainMenu) {
                            game.overlays.remove(GameScreen.wonDialogKey);
                            game.start();
                          } else {
                            context.go('/');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Retry', style: bodyTextStyle),
                        )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
