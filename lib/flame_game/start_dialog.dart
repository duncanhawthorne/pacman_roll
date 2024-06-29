import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../level_selection/levels.dart';
import '../main_menu/main_menu_screen.dart';
import '../settings/settings.dart';
import '../style/palette.dart';
import 'game_screen.dart';
import 'pacman_game.dart';

/// This dialog is shown when a level is won.
///
/// It shows what time the level was completed
/// and a comparison vs the leaderboard

class StartDialog extends StatelessWidget {
  const StartDialog({
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
    final settingsController = context.watch<SettingsController>();
    return Center(
      child: Container(
        //width: 480,
        //height: 300,
        decoration: BoxDecoration(
            border: Border.all(color: palette.borderColor.color, width: 3),
            borderRadius: BorderRadius.circular(10),
            color: palette.playSessionBackground.color),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Transform.rotate(
                angle: -0.1,
                child: Text('Pacman ROLL',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              Image.asset('assets/images/dash/ghost1.png',
                  filterQuality: FilterQuality.none, height: 92, width: 92),
              const SizedBox(height: 16),
              audioOnOffButton(settingsController,
                  color: palette.mainContrast.color),
              const SizedBox(height: 16),
              if (true) ...[
                TextButton(
                    style: TextButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        side: BorderSide(
                          color: Palette.blueMaze,
                          width: 3,
                        ),
                      ),
                    ),
                    onPressed: () {
                      game.overlays.remove(GameScreen.startDialogKey);
                      game.start();
                      //context.go('/');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Play',
                          style: TextStyle(
                              fontFamily: 'Press Start 2P',
                              color: palette.playSessionContrast.color)),
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
    );
  }
}
