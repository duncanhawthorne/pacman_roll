import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router.dart';
import '../../style/dialog.dart';
import '../game_screen.dart';
import '../maze/maze.dart';
import '../custom_game.dart';
import 'level_choose.dart';

/// This first dialog shown during playback mode

/// The initial dialog shown during the playback mode sequence.
class PlaybackDialog extends StatelessWidget {
  const PlaybackDialog({super.key, required this.game});

  final CustomGame game;

  @override
  Widget build(BuildContext context) {
    assert(game.playState == PlayState.playbackMode);
    return purePopup(
      child: TextButton(
        style: buttonStyle(),
        onPressed: () {
          game.overlays.remove(GameScreen.beginDialogKey);
          game.playState = PlayState.levelChooseScreen;
          context.go(
            '/?$levelUrlKey=${levelAfterPlaybackScreen(game)}&$mazeUrlKey=${mazeNames[Maze.defaultMazeId]}',
          );
        },
        child: const Padding(
          padding: EdgeInsets.all(12.0),
          child: Text("Start", style: textStyleBody),
        ),
      ),
    );
  }
}
