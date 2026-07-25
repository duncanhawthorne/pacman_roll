import 'dart:js_interop';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import '../components/base_component.dart';
import '../pacman_game.dart';

/// Captures web pointer lock click triggers and delegates mouse movement deltas to [DragRotation].
class MouseMove extends BaseComponent with HasGameReference<PacmanGame> {
  void requestPointerLockIfAllowed() {
    if (!kIsWeb) return;
    if (game.dialogs.anyDialogShowing()) return;

    if (web.document.pointerLockElement == null) {
      final web.Element? canvas = web.document.querySelector('canvas');
      if (canvas != null && canvas.isA<web.HTMLElement>()) {
        (canvas as web.HTMLElement).requestPointerLock();
      } else if (web.document.body != null) {
        web.document.body!.requestPointerLock();
      }
    }
  }

  /// Releases the mouse pointer lock if currently locked on the web.
  void exitPointerLock() {
    if (!kIsWeb) return;

    if (web.document.pointerLockElement != null) {
      web.document.exitPointerLock();
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (kIsWeb) {
      // Mousemove listener for relative deltas when pointer is locked
      web.document.addEventListener(
        'mousemove',
        (web.Event e) {
          final web.MouseEvent mouseEvent = e as web.MouseEvent;

          // Check if pointer lock is currently active
          if (web.document.pointerLockElement != null) {
            final double dx = -mouseEvent.movementX.toDouble();
            final double dy = mouseEvent.movementY.toDouble();

            game.world.dragRotate.onLockedCursorMove(dx, dy);
          }
        }.toJS,
      );
    }
  }
}
