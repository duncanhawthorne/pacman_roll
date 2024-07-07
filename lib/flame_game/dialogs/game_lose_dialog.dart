import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../level_selection/levels.dart';
import '../../style/palette.dart';
import '../game_screen.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'start_dialog.dart';

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
                    child: Text(
                      'Game Over',
                      style: headingTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                    child: Text(
                      "Dots left: ${game.world.pelletsRemainingNotifier.value}",
                      style: bodyTextStyle,
                    ),
                  ),
                  levelSelector(context, game),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                    child: TextButton(
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
