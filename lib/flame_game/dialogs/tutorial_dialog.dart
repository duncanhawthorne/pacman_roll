import 'package:flutter/material.dart';

import '../../style/dialog.dart';
import '../custom_game.dart';

/// A simple visual dialog used to instruct the user on game controls.
class TutorialDialog extends StatelessWidget {
  const TutorialDialog({super.key, required this.game});

  final CustomGame game;

  @override
  Widget build(BuildContext context) {
    return popupDialog(
      children: <Widget>[
        titleText(text: '←←←←←←←←\n↓      ↑\n↓ Drag ↑\n↓      ↑\n→→→→→→→→'),
      ],
    );
  }
}
