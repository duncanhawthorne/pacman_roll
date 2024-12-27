import 'dart:math';

import 'package:flutter/material.dart';

import '../../audio/audio_controller.dart';
import '../../audio/sounds.dart';
import '../../style/dialog.dart';
import '../pacman_game.dart';

/// This first dialog shown during playback mode

class DebugDialog extends StatelessWidget {
  const DebugDialog({
    super.key,
    required this.game,
  });

  final PacmanGame game;

  @override
  Widget build(BuildContext context) {
    //assert(game.debugModeManual);
    return popupDialog(children: <Widget>[
      TextButton(
        child: const Text("play siren"),
        onPressed: () {
          game.audioController.playSfx(SfxType.ghostsRoamingSiren);
        },
      ),
      TextButton(
        child: const Text("play pacmanDeath"),
        onPressed: () {
          game.audioController.playSfx(SfxType.pacmanDeath);
        },
      ),
      TextButton(
        child: const Text("play eatGhost"),
        onPressed: () {
          game.audioController.playSfx(SfxType.eatGhost);
        },
      ),
      TextButton(
        child: const Text("play silence"),
        onPressed: () {
          game.audioController.playSilence();
        },
      ),
      TextButton(
        child: const Text("play eatGhostAp"),
        onPressed: () {
          game.audioController.playEatGhostAP();
        },
      ),
      TextButton(
        child: const Text("ASYNC play eatGhost"),
        onPressed: () {
          Future<void>.delayed(const Duration(seconds: 1), () {
            game.audioController.playSfx(SfxType.eatGhost);
          });
        },
      ),
      TextButton(
        child: const Text("ASYNC play silence"),
        onPressed: () {
          Future<void>.delayed(const Duration(seconds: 1), () {
            game.audioController.playSilence();
          });
        },
      ),
      TextButton(
        child: const Text("soLoud deinit manual"),
        onPressed: () {
          soLoud.deinit();
        },
      ),
      TextButton(
        child: const Text("soLoud init manual"),
        onPressed: () {
          soLoud.init();
        },
      ),
      TextButton(
        child: const Text("stop silence"),
        onPressed: () {
          game.audioController.stopSound(SfxType.silence);
        },
      ),
      TextButton(
        child: const Text("stop all sound"),
        onPressed: () {
          game.audioController.stopAllSounds();
        },
      ),
      TextButton(
        child: const Text("dispose"),
        onPressed: () {
          game.audioController.dispose();
        },
      ),
      SizedBox(
        width: 800,
        child: ValueListenableBuilder<int>(
            valueListenable: game.audioController.debugLogListIterator,
            builder: (BuildContext context, int value, Widget? child) {
              final List<String> debugLogList =
                  game.audioController.debugLogList;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List<Widget>.generate(
                    min(30, debugLogList.length),
                    (int index) => Text(
                        debugLogList[debugLogList.length -
                            min(30, debugLogList.length).toInt() +
                            index],
                        softWrap: true),
                    growable: false),
              );
            }),
      ),
    ]);
  }
}
