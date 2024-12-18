import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../level_selection/levels.dart';
import '../../router.dart';
import '../../style/dialog.dart';
import '../game_screen.dart';
import '../maze.dart';
import '../pacman_game.dart';

/// This dialog is shown when a level is won.
///
/// It shows what time the level was completed
/// and a comparison vs the leaderboard

class BeginDialog extends StatelessWidget {
  const BeginDialog({
    super.key,
    required this.game,
  });

  final PacmanGame game;

  @override
  Widget build(BuildContext context) {
    assert(game.playbackMode);
    return purePopup(
        child: TextButton(
            style: buttonStyle(),
            onPressed: () {
              game.toggleOverlay(GameScreen.beginDialogKey);
              context.go(
                  '/?$levelUrlKey=${Levels.minLevel}&$mazeUrlKey=${mazeNames[Maze.defaultMazeId]}');
            },
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Start", style: textStyleBody),
            )));
  }
}
