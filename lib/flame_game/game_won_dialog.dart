import 'package:pacman_roll/flame_game/pacman_game.dart';

import '../level_selection/levels.dart';
import 'constants.dart';
import 'helper.dart';
import '../style/palette.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';

/// This dialog is shown when a level is completed.
///
/// It shows what time the level was completed in and if there are more levels
/// it lets the user go to the next level, or otherwise back to the level
/// selection screen.
///
///

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
            FutureBuilder(
                future: _endText(levelCompletedIn),
                initialData: _timeText(levelCompletedIn),
                builder: (BuildContext context, AsyncSnapshot<String> text) {
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
            //NesButton(
            //  onPressed: () {
            //    context.go('/play');
            //  },
            //  type: NesButtonType.normal,
            //  child: const Text('Level selection'),
            //),
          ],
        ),
      ),
    );
  }
}

Future<String> _endText(double levelCompletedIn) async {
  save.cacheLeaderboardNow(); //belts and braces. should have been called earlier in prep
  double x = fbOn
      ? _percentileOf(await save.leaderboardWinTimesCache!, levelCompletedIn) *
          100
      : 0.0;
  String y =
      "\nTime: ${levelCompletedIn.toStringAsFixed(1)} seconds\n${!fbOn || (await save.leaderboardWinTimesCache)!.isEmpty ? "" : "\nRank: ${x == 0 ? "World Record" : "Top ${x.toStringAsFixed(0)}%"}\n"}";
  return y;
}

String _timeText(double levelCompletedIn) {
  String y =
      "\nTime: ${levelCompletedIn.toStringAsFixed(1)} seconds\n${!fbOn ? "" : "\nRank: Loading...\n"}";
  return y;
}

double _percentileOf(List<double> list, double value) {
  List<double> tmpList = List<double>.from(list);
  tmpList.add(value);
  tmpList.sort();
  return tmpList.indexOf(value) / (tmpList.length - 1);
}
