import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../settings/settings.dart';
import '../style/palette.dart';
import '../utils/constants.dart';
import '../utils/helper.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    setStatusBarColor(palette.mainBackground.color);
    final settingsController = context.watch<SettingsController>();
    return Scaffold(
      backgroundColor: palette.mainBackground.color,
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
                        color: palette.mainContrast.color),
                  ),
                ),
              ),
              _gap,
              _gap,
              _gap,
              TextButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      side: BorderSide(
                        color: palette.borderColor.color,
                        width: 3,
                      ),
                    ),
                  ),
                  onPressed: () {
                    GoRouter.of(context).go('/session/1');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Play',
                        style: TextStyle(
                            fontFamily: 'Press Start 2P',
                            color: palette.mainContrast.color)),
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
                  color: palette.mainContrast.color),
              _gap,
            ],
          ),
        ),
      ),
    );
  }

  static const _gap = SizedBox(height: 40);
}

Widget audioOnOffButton(settingsController, {Color? color}) {
  return ValueListenableBuilder<bool>(
    valueListenable: settingsController.audioOn,
    builder: (context, audioOn, child) {
      return IconButton(
        onPressed: () => settingsController.toggleAudioOn(),
        icon: Icon(audioOn ? Icons.volume_up : Icons.volume_off, color: color),
      );
    },
  );
}
