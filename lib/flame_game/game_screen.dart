import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_lifecycle/app_lifecycle.dart';
import '../audio/audio_controller.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../style/palette.dart';
import '../utils/src/workarounds.dart';
import 'dialogs/debug_dialog.dart';
import 'dialogs/game_lose_dialog.dart';
import 'dialogs/game_overlays.dart';
import 'dialogs/game_won_dialog.dart';
import 'dialogs/level_choose.dart';
import 'dialogs/playback_dialog.dart';
import 'dialogs/reset_dialog.dart';
import 'dialogs/tutorial_dialog.dart';
import 'custom_game.dart';

/// This widget defines the properties of the game screen.
///
/// It mostly sets up the overlays (widgets shown on top of the Flame game) and
/// the gets the [AudioController] from the context and passes it in to the
/// [CustomGame] class so that it can play audio.

class GameScreen extends StatelessWidget {
  const GameScreen({required this.level, required this.mazeId, super.key});

  /// The level configuration for this session.
  final GameLevel level;

  /// The ID of the maze to load.
  final int mazeId;

  static const String loseDialogKey = 'lose_dialog';
  static const String wonDialogKey = 'won_dialog';
  static const String startDialogKey = 'start_dialog';
  static const String tutorialDialogKey = 'tutorial_dialog';
  static const String resetDialogKey = 'reset_dialog';
  static const String beginDialogKey = 'begin_dialog';
  static const String topOverlayKey = 'top_overlay';
  static const String debugDialogKey = 'debug_dialog';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        decoration: BoxDecoration(color: Palette.background.color),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: gestureInset()),
            child: Scaffold(
              backgroundColor: Palette.background.color,
              body: GameWidget<CustomGame>(
                key: const Key('play session'),
                game: CustomGame(
                  level: level,
                  mazeId: mazeId,
                  playerProgress: context.read<PlayerProgress>(),
                  audioController: context.read<AudioController>(),
                  appLifecycleStateNotifier: context
                      .read<AppLifecycleStateNotifier>(),
                ),
                overlayBuilderMap: <String, OverlayWidgetBuilder<CustomGame>>{
                  topOverlayKey: (BuildContext context, CustomGame game) {
                    return topOverlayWidget(context, game);
                  },
                  loseDialogKey: (BuildContext context, CustomGame game) {
                    return GameLoseDialog(level: level, game: game);
                  },
                  wonDialogKey: (BuildContext context, CustomGame game) {
                    return GameWonDialog(
                      level: level,
                      levelCompletedInMillis:
                          game.session.stopwatchMilliSeconds,
                      game: game,
                    );
                  },
                  startDialogKey: (BuildContext context, CustomGame game) {
                    return LevelChooseDialog(level: level, game: game);
                  },
                  tutorialDialogKey: (BuildContext context, CustomGame game) {
                    return TutorialDialog(game: game);
                  },
                  resetDialogKey: (BuildContext context, CustomGame game) {
                    return ResetDialog(game: game);
                  },
                  beginDialogKey: (BuildContext context, CustomGame game) {
                    return PlaybackDialog(game: game);
                  },
                  debugDialogKey: (BuildContext context, CustomGame game) {
                    return DebugDialog(game: game);
                  },
                },
                initialActiveOverlays: const <String>[topOverlayKey],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
