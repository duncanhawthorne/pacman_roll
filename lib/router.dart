import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'flame_game/game_screen.dart';
import 'flame_game/maze/maze.dart';
import 'level_selection/levels.dart';

/// The router describes the game's navigational hierarchy, from the main
/// screen through settings screens all the way to each individual level.

/// Key for the level parameter in the URL.
const String levelUrlKey = "level";

/// Key for the maze parameter in the URL.
const String mazeUrlKey = "maze";

final Map<String, int> _reversedMazeNames = <String, int>{
  for (final MapEntry<int, String> entry in mazeNames.entries)
    entry.value: entry.key,
};

/// Main router configuration for the application.
final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        final GameLevel level = _parseGameLevel(
          state.uri.queryParameters[levelUrlKey],
        );
        int mazeId = _parseMazeId(state.uri.queryParameters[mazeUrlKey]);
        if (level.isTutorial && !isTutorialMaze(mazeId)) {
          mazeId = Maze.tutorialMazeId;
        }
        if (!level.isTutorial && isTutorialMaze(mazeId)) {
          mazeId = Maze.defaultMazeId;
        }
        return GameScreen(level: level, mazeId: mazeId);
      },
    ),
  ],
);

GameLevel _parseGameLevel(String? levelString) {
  final int levelNumber =
      int.tryParse(levelString ?? '') ?? Levels.defaultLevelNum;
  return levels.getLevel(levelNumber);
}

int _parseMazeId(String? mazeString) {
  return _reversedMazeNames[mazeString ?? ''] ?? Maze.defaultMazeId;
}
