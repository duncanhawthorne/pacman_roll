import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../level_selection/levels.dart';
import '../../style/dialog.dart';
import '../game_screen.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'game_start_dialog.dart';

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
    return pacmanDialog(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          titleText(text: 'Game Over'),
          bodyWidget(
            child: Text(
              "Dots left: ${game.world.pelletsRemainingNotifier.value}",
              style: textStyleBody,
            ),
          ),
          levelSelector(context, game),
          bottomRowWidget(
            children: [
              TextButton(
                  style: buttonStyleNormal,
                  onPressed: () {
                    if (overlayMainMenu) {
                      game.overlays.remove(GameScreen.loseDialogKey);
                      game.start();
                    } else {
                      context.go('/');
                    }
                  },
                  child: Text('Retry', style: textStyleBody)),
            ],
          ),
        ],
      ),
    );
  }
}
