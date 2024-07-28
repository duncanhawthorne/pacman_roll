// ignore_for_file: unused_import

import 'package:elapsed_time_display/elapsed_time_display.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../settings/settings.dart';
import '../game_screen.dart';
import '../icons/pacman_icons.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';

Widget topLeftOverlayWidget(BuildContext context, PacmanGame game) {
  final settingsController = context.watch<SettingsController>();
  return Positioned(
    top: 20,
    left: 25, //30
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            game.showMainMenu();
          },
          icon: const Icon(Icons.menu, color: Colors.white),
        ),
        const SizedBox(width: 20 * statusWidgetHeightFactor, height: 1),
        audioOnOffButton(settingsController, color: Colors.white),
      ],
    ),
  );
}

Widget topRightOverlayWidget(BuildContext context, PacmanGame game) {
  return Positioned(
    top: 27,
    right: 30,
    child: Container(
      height: statusWidgetHeight.toDouble(),
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //FIXME first ElapsedTimeDisplay shouldn't be necessary
          //but without it the pacman icon doesn't animate
          ElapsedTimeDisplay(
            startTime: DateTime.now(), //actually ignored
            interval: const Duration(milliseconds: 100),
            style: const TextStyle(
                fontSize: 1 * statusWidgetHeightFactor,
                color: Colors.transparent,
                fontFamily: 'Press Start 2P'),
            formatter: (elapsedTime) {
              return elapsedTime.milliseconds.toString().padLeft(4, " ");
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: game.world.numberOfDeathsNotifier,
            builder: (BuildContext context, int value, Widget? child) {
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(
                      game.level.maxAllowedDeaths,
                      (index) => Padding(
                          padding: const EdgeInsets.fromLTRB(
                              4 * statusWidgetHeightFactor,
                              0,
                              4 * statusWidgetHeightFactor,
                              0),
                          child: animatedPacmanIcon(game, index))));
            },
          ),
          const SizedBox(width: 20 * statusWidgetHeightFactor, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 3, 0, 0),
            child: ElapsedTimeDisplay(
              startTime: DateTime.now(), //actually ignored
              interval: const Duration(milliseconds: 100),
              style: const TextStyle(
                  fontSize: 18 * statusWidgetHeightFactor,
                  color: Colors.white,
                  fontFamily: 'Press Start 2P'),
              formatter: (elapsedTime) {
                return (game.stopwatchMilliSeconds / 1000)
                    .toStringAsFixed(1)
                    .padLeft(4, " ");
              },
            ),
          ),
        ],
      ),
    ),
  );
}

Widget audioOnOffButton(settingsController, {Color? color}) {
  return ValueListenableBuilder<bool>(
    valueListenable: settingsController.audioOn,
    builder: (context, audioOn, child) {
      return IconButton(
        onPressed: () => settingsController.toggleAudioOn(),
        icon: Icon(audioOn ? Icons.volume_up : Icons.volume_off, color: color),
      );
    },
  );
}
