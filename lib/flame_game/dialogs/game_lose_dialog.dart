import 'package:flutter/material.dart';

import '../../level_selection/levels.dart';
import '../../style/dialog.dart';
import '../game_screen.dart';
import '../custom_game.dart';
import 'level_choose.dart';

/// This dialog is shown when a level is lost.

/// Dialog displayed when the user loses the game.
class GameLoseDialog extends StatelessWidget {
  const GameLoseDialog({super.key, required this.level, required this.game});

  /// The properties of the level that was just lost.
  final GameLevel level;
  final CustomGame game;

  @override
  Widget build(BuildContext context) {
    return popupDialog(
      children: <Widget>[
        titleText(text: 'Game Over'),
        bodyWidget(
          child: Text(
            "Dots left: ${game.session.itemsRemainingNotifier.value}",
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
                game
                  ..resetAndStart()
                  ..playState = PlayState.gaming;
              },
              child: const Text('Retry', style: textStyleBody),
            ),
          ],
        ),
      ],
    );
  }
}
