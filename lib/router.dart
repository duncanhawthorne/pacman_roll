import 'package:go_router/go_router.dart';

import 'flame_game/game_screen.dart';
import 'flame_game/maze.dart';
import 'level_selection/levels.dart';

/// The router describes the game's navigational hierarchy, from the main
/// screen through settings screens all the way to each individual level.

const String levelUrlKey = "level";
const String mazeUrlKey = "maze";

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        final level = _parseGameLevel(state.uri.queryParameters[levelUrlKey]);
        final mazeId = _parseMazeId(state.uri.queryParameters[mazeUrlKey]);
        return GameScreen(level: level, mazeId: mazeId);
      },
    ),
  ],
);

GameLevel _parseGameLevel(String? levelString) {
  int levelNumberRaw = 1;
  try {
    levelNumberRaw = int.parse(levelString ?? "1");
  } catch (e) {
    //stick with default
  }
  return levelNumberRaw - 1 < gameLevels.length && levelNumberRaw >= 1
      ? gameLevels[levelNumberRaw - 1]
      : gameLevels[0];
}

int _parseMazeId(String? levelString) {
  final mazeIdRaw = levelString ?? "A";
  return !mazeNames.contains(mazeIdRaw) ? 0 : mazeNames.indexOf(mazeIdRaw);
}
