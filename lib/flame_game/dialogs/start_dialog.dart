import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../level_selection/levels.dart';
import '../../style/palette.dart';
import '../../utils/constants.dart';
import '../game_screen.dart';
import '../pacman_game.dart';

/// This dialog is shown before starting the game.

class StartDialog extends StatelessWidget {
  const StartDialog({
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
              padding: const EdgeInsets.fromLTRB(40, 4, 40, 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16 + 16, 0, 16),
                    child: Transform.rotate(
                      angle: -0.1,
                      child: Text(appTitle,
                          style: headingTextStyle, textAlign: TextAlign.center),
                    ),
                  ),
                  levelSelector(context, game),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                    child: game.levelStarted
                        ? Row(
                            children: [
                              TextButton(
                                  style: buttonStyleWarning,
                                  onPressed: () {
                                    if (!game.world.doingLevelResetFlourish) {
                                      game.overlays
                                          .remove(GameScreen.startDialogKey);
                                      game.start();
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text('Reset', style: bodyTextStyle),
                                  )),
                              const SizedBox(width: 10),
                              TextButton(
                                  style: buttonStyle,
                                  onPressed: () {
                                    game.overlays
                                        .remove(GameScreen.startDialogKey);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text('Resume', style: bodyTextStyle),
                                  ))
                            ],
                          )
                        : TextButton(
                            style: buttonStyle,
                            onPressed: () {
                              game.overlays.remove(GameScreen.startDialogKey);
                              game.start();
                              //context.go('/');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text('Play', style: bodyTextStyle),
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

Widget levelSelector(BuildContext context, PacmanGame game) {
  return game.world.playerProgress.levels.isEmpty && game.level.number == 1
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
          child: Row(
            children: [
              Text('Level:', style: bodyTextStyle),
              const SizedBox(width: 10),
              ...List.generate(
                  min(
                      gameLevels.length,
                      max(game.level.number,
                          game.world.playerProgress.levels.length + 1)),
                  (index) => Padding(
                        padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                        child: TextButton(
                            style: game.level.number == index + 1
                                ? buttonStyle
                                : buttonStylePassive,
                            onPressed: () {
                              context.go('/session/${index + 1}');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('${index + 1}', style: bodyTextStyle),
                            )),
                      )),
            ],
          ),
        );
}
