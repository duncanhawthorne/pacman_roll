import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'flame_game/game_screen.dart';
//import 'level_selection/level_selection_screen.dart';
import 'flame_game/pacman_world.dart';
import 'level_selection/levels.dart';
//import 'settings/settings_screen.dart';
import 'main_menu/main_menu_screen.dart';
import 'style/page_transition.dart';
import 'style/palette.dart';

/// The router describes the game's navigational hierarchy, from the main
/// screen through settings screens all the way to each individual level.
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return overlayMainMenu
            ? GameScreen(level: gameLevels[0])
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
          path: 'session/:level',
          pageBuilder: (context, state) {
            final levelNumber = int.parse(state.pathParameters['level']!);
            final level = levelNumber - 1 < gameLevels.length
                ? gameLevels[levelNumber - 1]
                : gameLevels[0]; //avoid crash if type in high level

            return buildPageTransition<void>(
              key: const ValueKey('level'),
              color: context.watch<Palette>().pageTransition.color,
              child: GameScreen(level: level),
            );
          },
        ),
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
