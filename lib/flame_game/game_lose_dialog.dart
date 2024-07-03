import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../level_selection/levels.dart';
import '../style/palette.dart';
import 'game_screen.dart';
import 'pacman_game.dart';
import 'pacman_world.dart';

/// This dialog is shown when a level is lost.

class GameLoseDialog extends StatelessWidget {
  const GameLoseDialog({
    super.key,
    required this.level,
    required this.game,
  });

  /// The properties of the level that was just finished.
  final GameLevel level;
  final PacmanGame game;

  @override
  Widget build(BuildContext context) {
    //context.read<Palette>();
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(75.0),
          child: Container(
            //width: 420,
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
                  Text(
                    'Game Over',
                    style: headingTextStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  Text(
                    "Dots left: ${game.world.pelletsRemainingNotifier.value}",
                    style: bodyTextStyle,
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  if (true) ...[
                    TextButton(
                        style: buttonStyle,
                        onPressed: () {
                          if (overlayMainMenu) {
                            game.overlays.remove(GameScreen.loseDialogKey);
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
          ),
        ),
      ),
    );
  }
}
