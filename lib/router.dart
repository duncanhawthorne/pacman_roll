import 'package:go_router/go_router.dart';

import 'flame_game/game_screen.dart';
import 'flame_game/maze.dart';
import 'level_selection/levels.dart';

/// The router describes the game's navigational hierarchy, from the main
/// screen through settings screens all the way to each individual level.

const String levelUrl = "level";
const String mapUrl = "maze";

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        int levelNumberRaw = 1;
        try {
          levelNumberRaw =
              int.parse(state.uri.queryParameters[levelUrl] ?? "1");
        } catch (e) {
          //stick with default
        }
        final level =
            levelNumberRaw - 1 < gameLevels.length && levelNumberRaw >= 1
                ? gameLevels[levelNumberRaw - 1]
                : gameLevels[0];
        final mazeIdRaw = state.uri.queryParameters[mapUrl] ?? "A";
        final mazeId =
            !mazeNames.contains(mazeIdRaw) ? 0 : mazeNames.indexOf(mazeIdRaw);
        return GameScreen(level: level, mazeId: mazeId);
      },
    ),
  ],
);
