import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../style/dialog.dart';
import '../../style/palette.dart';
import '../../utils/constants.dart';
import '../game_screen.dart';
import '../pacman_game.dart';

/// This dialog is shown when a level is won.
///
/// It shows what time the level was completed
/// and a comparison vs the leaderboard

class ResetDialog extends StatelessWidget {
  const ResetDialog({super.key, required this.game});

  final PacmanGame game;

  @override
  Widget build(BuildContext context) {
    return popupDialog(
      children: <Widget>[
        titleText(text: appTitle),
        bottomRowWidget(
          children: <Widget>[
            TextButton(
              style: buttonStyle(),
              onPressed: () {
                game.overlays.remove(GameScreen.resetDialogKey);
              },
              child: const Text("Cancel", style: textStyleBody),
            ),
            TextButton(
              style: buttonStyle(borderColor: Palette.warning.color),
              onPressed: () {
                game.playerProgress.reset();
                game.overlays.remove(GameScreen.resetDialogKey);
                context.go('/');
              },
              child: const Text("Reset completed levels", style: textStyleBody),
            ),
          ],
        ),
      ],
    );
  }
}
