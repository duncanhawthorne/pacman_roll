import '../audio/audio_controller.dart';
import 'endless_runner.dart';
import 'constants.dart';

import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';

import 'game_lose_dialog.dart';
import 'game_won_dialog.dart';

/// This widget defines the properties of the game screen.
///
/// It mostly sets up the overlays (widgets shown on top of the Flame game) and
/// the gets the [AudioController] from the context and passes it in to the
/// [EndlessRunner] class so that it can play audio.
class GameScreen extends StatelessWidget {
  const GameScreen({required this.level, super.key});

  final GameLevel level;

  static const String loseDialogKey = 'lose_dialog';
  static const String wonDialogKey = 'won_dialog';
  static const String backButtonKey = 'back_buttton';

  @override
  Widget build(BuildContext context) {
    final audioController = context.read<AudioController>();
    return Scaffold(
      body: GameWidget<EndlessRunner>(
        key: const Key('play session'),
        game: EndlessRunner(
          level: level,
          playerProgress: context.read<PlayerProgress>(),
          audioController: audioController,
        ),
        overlayBuilderMap: {
          backButtonKey: (BuildContext context, EndlessRunner game) {
            return Positioned(
              top: 20,
              left: 10,
              child: Transform.scale(
                scale: 0.6,
                child: NesButton(
                  type: NesButtonType.normal,
                  onPressed: () =>
                      {GoRouter.of(context).go("/"), gameRunning = false},
                  child: NesIcon(iconData: NesIcons.leftArrowIndicator),
                ),
              ),
            );
          },
          loseDialogKey: (BuildContext context, EndlessRunner game) {
            return GameLoseDialog(
              level: level,
              levelCompletedIn: game.world.levelCompletedIn,
            );
          },
          wonDialogKey: (BuildContext context, EndlessRunner game) {
            return GameWonDialog(
              level: level,
              levelCompletedIn: game.world.getLevelTimeSeconds(),
            );
          },
        },
      ),
    );
  }
}
