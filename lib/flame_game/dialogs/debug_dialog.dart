import 'dart:math';

import 'package:flutter/material.dart';

import '../../audio/audio_controller.dart';
import '../../audio/sounds.dart';
import '../../style/dialog.dart';
import '../../utils/helper.dart';
import '../pacman_game.dart';

/// This first dialog shown during playback mode

class DebugDialog extends StatelessWidget {
  const DebugDialog({super.key, required this.game});

  final PacmanGame game;

  @override
  Widget build(BuildContext context) {
    return popupDialog(
      spacing: 8,
      children: <Widget>[
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
          child: const Text("soLoud deinit manual"),
          onPressed: () {
            game.audioController.soLoudDeInitOnly();
          },
        ),
        TextButton(
          child: const Text("soLoud init manual"),
          onPressed: () {
            logGlobal("soLoud init pure manual");
            soLoud.init();
          },
        ),
        TextButton(
          child: const Text("soLoud init wrapper"),
          onPressed: () {
            game.audioController.soLoudEnsureInitialised();
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
          child: const Text("soLoudDisposeAllSources()"),
          onPressed: () {
            game.audioController.soLoudDisposeAllSources();
          },
        ),
        TextButton(
          child: const Text("soLoudReset"),
          onPressed: () {
            game.audioController.soLoudPowerDownForReset();
          },
        ),
        ...List<Widget>.generate(
          checkboxes.length,
          (int i) => _checkboxRow(checkboxes.keys.toList()[i]),
        ),
        SizedBox(
          width: 800,
          height: 600,
          child: ValueListenableBuilder<int>(
            valueListenable: debugLogListNotifier,
            builder: (BuildContext context, int value, Widget? child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List<Widget>.generate(
                  min(debugLogListMaxLength, debugLogList.length),
                  (int index) => Text(
                    debugLogList[debugLogList.length -
                        min(
                          debugLogListMaxLength,
                          debugLogList.length,
                        ).toInt() +
                        index],
                    softWrap: true,
                  ),
                  growable: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Widget _checkboxRow(String key) {
  return Row(children: <Widget>[Text(key), _checkbox(checkboxes[key]!)]);
}

Widget _checkbox(ValueNotifier<bool> x) {
  return ValueListenableBuilder<bool>(
    valueListenable: x,
    builder: (BuildContext context, bool value, Widget? child) {
      return Checkbox(
        value: x.value,
        onChanged: (bool? newValue) {
          x.value = !x.value;
        },
      );
    },
  );
}
