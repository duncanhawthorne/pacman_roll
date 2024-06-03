import 'package:pacman_roll/flame_game/pacman_game.dart';
import 'package:pacman_roll/flame_game/saves.dart';

import '../level_selection/levels.dart';
import 'constants.dart';
import '../style/palette.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';

/// This dialog is shown when a level is won.
///
/// It shows what time the level was completed
/// and a comparison vs the leaderboard

class GameWonDialog extends StatelessWidget {
  const GameWonDialog({
    super.key,
    required this.level,
    required this.levelCompletedIn,
    required this.game,
  });

  /// The properties of the level that was just finished.
  final GameLevel level;

  final PacmanGame game;

  /// How many seconds that the level was completed in.
  final double levelCompletedIn;

  @override
  Widget build(BuildContext context) {
    final palette = context.read<Palette>();
    return Center(
      child: NesContainer(
        width: 480,
        height: 300,
        backgroundColor: palette.backgroundPlaySession.color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('You won',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              _levelCompleteText(levelCompletedIn),
              style: const TextStyle(fontFamily: 'Press Start 2P'),
            ),
            !firebaseOn
                ? const SizedBox.shrink()
                : FutureBuilder(
                    future: _scoreboardRankText(levelCompletedIn),
                    initialData: _scoreboardLoadingText(),
                    builder:
                        (BuildContext context, AsyncSnapshot<String> text) {
                      return Text(
                        text.data!,
                        style: const TextStyle(fontFamily: 'Press Start 2P'),
                      );
                    }),
            const SizedBox(height: 16),
            if (true) ...[
              NesButton(
                onPressed: () {
                  context.go('/');
                },
                type: NesButtonType.primary,
                child: const Text('Retry',
                    style: TextStyle(fontFamily: 'Press Start 2P')),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

String _levelCompleteText(double levelCompletedIn) {
  String y = "\nTime: ${levelCompletedIn.toStringAsFixed(1)} seconds\n";
  return y;
}

String _scoreboardLoadingText() {
  String y = !firebaseOn ? "" : "Rank: Loading...\n";
  return y;
}

Future<String> _scoreboardRankText(double levelCompletedIn) async {
  save.cacheLeaderboardNow(); //belts and braces. should have been called earlier in prep
  double x = firebaseOn
      ? _percentileOf(await save.leaderboardWinTimesCache!, levelCompletedIn) *
          100
      : 0.0;
  String y = !firebaseOn || (await save.leaderboardWinTimesCache)!.isEmpty
      ? ""
      : "Rank: ${x == 0 ? "World Record" : "Top ${x.toStringAsFixed(0)}%"}\n";
  return y;
}

double _percentileOf(List<double> list, double value) {
  List<double> tmpList = List<double>.from(list);
  tmpList.add(value);
  tmpList.sort();
  return tmpList.indexOf(value) / (tmpList.length - 1);
}
