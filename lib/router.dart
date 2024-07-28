import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'flame_game/game_screen.dart';
//import 'level_selection/level_selection_screen.dart';
import 'flame_game/maze.dart';
import 'flame_game/pacman_world.dart';
import 'level_selection/levels.dart';
//import 'settings/settings_screen.dart';
import 'main_menu/main_menu_screen.dart';

/// The router describes the game's navigational hierarchy, from the main
/// screen through settings screens all the way to each individual level.

const String levelUrl = "level";
const String mapUrl = "map";

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return overlayMainMenu
            ? GameScreen(level: gameLevels[0], mazeId: 0)
            : const MainMenuScreen(key: Key('main menu'));
      },
      //routes: [
      //  GoRoute(
      //    path: 'play',
      //    pageBuilder: (context, state) => buildPageTransition<void>(
      //      key: const ValueKey('play'),
      //      color: context.watch<Palette>().backgroundLevelSelection.color,
      //      child: const LevelSelectionScreen(
      //        key: Key('level selection'),
      //      ),
      //    ),
      routes: [
        GoRoute(
            path: '$levelUrl/:level',
            builder: (context, state) {
              final levelNumber = int.parse(state.pathParameters['level']!);
              final level = levelNumber - 1 < gameLevels.length
                  ? gameLevels[levelNumber - 1]
                  : gameLevels[0]; //avoid crash if type in high level

              return GameScreen(level: level, mazeId: 0);
            },
            routes: [
              GoRoute(
                path: '$mapUrl/:map',
                builder: (context, state) {
                  final levelNumber = int.parse(state.pathParameters['level']!);
                  final level = levelNumber - 1 < gameLevels.length
                      ? gameLevels[levelNumber - 1]
                      : gameLevels[0]; //avoid crash if type in high level
                  final mapName = state.pathParameters['map']!;
                  final mazeId = !mazeNames.contains(mapName)
                      ? 0
                      : mazeNames.indexOf(mapName);
                  return GameScreen(level: level, mazeId: mazeId);
                },
              ),
            ]),
      ],
      //),
      //  GoRoute(
      //    path: 'settings',
      //    builder: (context, state) => const SettingsScreen(
      //      key: Key('settings'),
      //    ),
      //  ),
      //],
    ),
  ],
);
