import 'package:flutter/material.dart';

import '../../style/dialog.dart';
import '../pacman_game.dart';

class TutorialDialog extends StatelessWidget {
  const TutorialDialog({
    super.key,
    required this.game,
  });

  final PacmanGame game;

  @override
  Widget build(BuildContext context) {
    return popupDialog(
      children: <Widget>[
        titleText(text: '←←←←←←←←\n↓      ↑\n↓ Drag ↑\n↓      ↑\n→→→→→→→→'),
      ],
    );
  }
}
