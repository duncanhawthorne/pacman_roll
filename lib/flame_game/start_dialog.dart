import 'package:flutter/material.dart';

import '../level_selection/levels.dart';
import '../style/palette.dart';
import '../utils/constants.dart';
import 'game_screen.dart';
import 'pacman_game.dart';

/// This dialog is shown before starting the game.

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
    //context.read<Palette>();
    //final settingsController = context.watch<SettingsController>();
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
              padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Transform.rotate(
                    angle: -0.1,
                    child: Text(appTitle,
                        style: headingTextStyle,
                        //Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 16),
                  /*
                  const SizedBox(height: 16),
                  Image.asset('assets/images/dash/ghost1.png',
                      filterQuality: FilterQuality.none, height: 92, width: 92),
                  const SizedBox(height: 16),
                  audioOnOffButton(settingsController,
                      color: Palette.mainContrast.color),

                   */
                  const SizedBox(height: 16),
                  if (true) ...[
                    game.levelStarted
                        ? Row(
                            children: [
                              TextButton(
                                  style: buttonStyleWarning,
                                  onPressed: () {
                                    if (!game.world.doingLevelResetFlourish) {
                                      game.overlays
                                          .remove(GameScreen.startDialogKey);
                                      game.start();
                                    }
                                    //context.go('/');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text('Reset', style: bodyTextStyle),
                                  )),
                              const SizedBox(width: 10),
                              TextButton(
                                  style: buttonStyle,
                                  onPressed: () {
                                    game.overlays
                                        .remove(GameScreen.startDialogKey);
                                    //game.resumeEngine();
                                    //game.stopwatch.start();
                                    //context.go('/');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text('Resume', style: bodyTextStyle),
                                  ))
                            ],
                          )
                        : TextButton(
                            style: buttonStyle,
                            onPressed: () {
                              game.overlays.remove(GameScreen.startDialogKey);
                              game.start();
                              //context.go('/');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text('Play', style: bodyTextStyle),
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
