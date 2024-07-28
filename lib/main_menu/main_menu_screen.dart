import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../flame_game/dialogs/game_overlays.dart';
import '../router.dart';
import '../settings/settings.dart';
import '../style/dialog.dart';
import '../style/palette.dart';
import '../utils/constants.dart';
import '../utils/helper.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    //context.watch<Palette>();
    setStatusBarColor(Palette.mainBackground.color);
    final settingsController = context.watch<SettingsController>();
    return Scaffold(
      backgroundColor: Palette.mainBackground.color,
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _gap,
              _gap,
              _gap,
              Image.asset('assets/images/dash/ghost1.png',
                  filterQuality: FilterQuality.none, height: 160, width: 160),
              _gap,
              Transform.rotate(
                angle: -0.1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Text(
                    appTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Press Start 2P',
                        fontSize: 32,
                        height: 1,
                        color: Palette.mainContrast.color),
                  ),
                ),
              ),
              _gap,
              _gap,
              _gap,
              TextButton(
                  style: buttonStyle(),
                  onPressed: () {
                    GoRouter.of(context).go('/$levelUrl/1');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Play', style: textStyleBody),
                  )),
              /*
              WobblyButton(
                onPressed: () {
                  GoRouter.of(context).go('/session/1');
                },
                child: const Text('Play',
                    style: TextStyle(fontFamily: 'Press Start 2P')),
              ),
               */
              _gap,
              audioOnOffButton(settingsController,
                  color: Palette.mainContrast.color),
              _gap,
            ],
          ),
        ),
      ),
    );
  }

  static const _gap = SizedBox(height: 40);
}
