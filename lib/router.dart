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
        int mazeId = _parseMazeId(state.uri.queryParameters[mazeUrlKey]);
        if (level.isTutorial && !isTutorialMaze(mazeId)) {
          mazeId = Maze.tutorialMazeId;
        }
        if (isTutorialMaze(mazeId) && !level.isTutorial) {
          mazeId = Maze.defaultMazeId;
        }
        return GameScreen(level: level, mazeId: mazeId);
      },
    ),
  ],
);

GameLevel _parseGameLevel(String? levelString) {
  int levelNumberRaw = Levels.defaultLevelNum;
  try {
    levelNumberRaw = int.parse(levelString ?? levelNumberRaw.toString());
  } catch (e) {
    //stick with default
  }
  return levels.getLevel(levelNumberRaw);
}

int _parseMazeId(String? levelString) {
  final mazeIdRaw = levelString ?? mazeNames[Maze.defaultMazeId];
  return !mazeNames.containsValue(mazeIdRaw)
      ? Maze.defaultMazeId
      : _reverseMap(mazeNames)[mazeIdRaw];
}

Map _reverseMap(Map map) => {for (var e in map.entries) e.value: e.key};
