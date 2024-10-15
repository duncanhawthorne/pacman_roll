import 'package:flutter/material.dart';

import '../../level_selection/levels.dart';
import '../../style/dialog.dart';
import '../game_screen.dart';
import '../pacman_game.dart';
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
    return popupDialog(
      children: <Widget>[
        titleText(text: 'Game Over'),
        bodyWidget(
          child: Text(
            "Dots left: ${game.world.pellets.pelletsRemainingNotifier.value}",
            style: textStyleBody,
          ),
        ),
        levelSelector(context, game),
        mazeSelector(context, game),
        bottomRowWidget(
          children: <Widget>[
            TextButton(
                style: buttonStyle(),
                onPressed: () {
                  game.overlays.remove(GameScreen.loseDialogKey);
                  game.resetAndStart();
                },
                child: const Text('Retry', style: textStyleBody)),
          ],
        ),
      ],
    );
  }
}
