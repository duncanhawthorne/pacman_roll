import 'dart:async';

import 'package:flame/components.dart';

import '../components/base_component.dart';
import '../custom_game.dart';
import '../custom_world.dart';
import '../game_screen.dart';

/// Manages the display and cleaning of game dialog overlays.
///
/// This includes start, lose, won, tutorial, reset, and debug dialogs.
class DialogManager extends BaseComponent with HasWorldReference<CustomWorld> {
  late final CustomGame game;

  /// Removes all active game dialog overlays.
  void clean() {
    game.overlays
      ..remove(GameScreen.startDialogKey)
      ..remove(GameScreen.loseDialogKey)
      ..remove(GameScreen.wonDialogKey)
      ..remove(GameScreen.tutorialDialogKey)
      ..remove(GameScreen.resetDialogKey)
      ..remove(GameScreen.debugDialogKey);
  }

  bool anyDialogShowing() {
    const List<String> dialogKeys = <String>[
      GameScreen.startDialogKey,
      GameScreen.loseDialogKey,
      GameScreen.wonDialogKey,
      GameScreen.tutorialDialogKey,
      GameScreen.resetDialogKey,
      GameScreen.debugDialogKey,
    ];
    return dialogKeys.any(game.overlays.isActive);
  }

  void switchTo(String overlayKey) {
    clean();
    game.overlays.add(overlayKey);
  }

  /// Toggles the visibility of a specific dialog overlay.
  ///
  /// If the dialog is currently visible, it will be removed. Otherwise,
  /// all other dialogs will be cleaned, and the specified dialog will be added.
  void toggle(String overlayKey) {
    if (game.overlays.activeOverlays.contains(overlayKey)) {
      game.overlays.remove(overlayKey);
    } else {
      switchTo(overlayKey);
    }
  }

  @override
  Future<void> onRemove() async {
    clean();
  }
}
