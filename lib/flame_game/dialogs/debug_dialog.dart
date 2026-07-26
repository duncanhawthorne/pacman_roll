import 'dart:math';

import 'package:flutter/material.dart';

import '../../style/dialog.dart';
import '../../utils/helper.dart';
import '../custom_game.dart';

/// This first dialog shown during playback mode

/// A dialog providing various debugging tools and logs for game state and audio.
class DebugDialog extends StatelessWidget {
  const DebugDialog({super.key, required this.game});

  final CustomGame game;

  @override
  Widget build(BuildContext context) {
    return popupDialog(
      spacing: 8,
      children: <Widget>[
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
