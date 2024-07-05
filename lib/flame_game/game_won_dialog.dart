import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../firebase/firebase_saves.dart';
import '../level_selection/levels.dart';
import '../style/palette.dart';
import 'game_screen.dart';
import 'pacman_game.dart';
import 'pacman_world.dart';

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
    //context.read<Palette>();
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(75.0),
          child: Container(
            //width: 480,
            //height: 300,
            decoration: BoxDecoration(
                border: Border.all(color: Palette.borderColor.color, width: 3),
                borderRadius: BorderRadius.circular(10),
                color: Palette.playSessionBackground.color),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40.0, 20, 40, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Complete',
                      style: headingTextStyle, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  Text(
                    _levelCompleteText(levelCompletedInMillis),
                    style: bodyTextStyle,
                  ),
                  !Save.firebaseOn
                      ? const SizedBox.shrink()
                      : FutureBuilder(
                          future: _scoreboardRankText(levelCompletedInMillis),
                          initialData: _scoreboardLoadingText(),
                          builder: (BuildContext context,
                              AsyncSnapshot<String> text) {
                            return Text(
                              text.data!,
                              style: bodyTextStyle,
                            );
                          }),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  if (true) ...[
                    TextButton(
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
                    /*
                    NesButton(
                      onPressed: () {
                        context.go('/');
                      },
                      type: NesButtonType.primary,
                      child: const Text('Retry',
                          style: TextStyle(fontFamily: 'Press Start 2P')),
                    ),

                     */
                    //const SizedBox(height: 16),
                  ],
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
  String y =
      "Time: ${(levelCompletedInMillis / 1000).toStringAsFixed(1)} seconds";
  return y;
}

String _scoreboardLoadingText() {
  String y = !Save.firebaseOn ? "" : "\nRank: Loading...";
  return y;
}

Future<String> _scoreboardRankText(int levelCompletedInMillis) async {
  double x = Save.firebaseOn
      ? (await save.firebasePercentile(levelCompletedInMillis)) * 100.0
      : 100.0;
  String y = !Save.firebaseOn
      ? ""
      : "\nRank: ${x == 0 ? "World Record" : "Top ${x.toStringAsFixed(0)}%"}";
  return y;
}
