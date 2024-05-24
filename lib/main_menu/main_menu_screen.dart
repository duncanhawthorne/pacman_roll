import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../settings/settings.dart';
import '../style/palette.dart';
import '../style/wobbly_button.dart';
import '../flame_game/constants.dart';
import '../flame_game/helper.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    setStatusBarColor(palette.backgroundMain.color);
    final settingsController = context.watch<SettingsController>();
    return Scaffold(
      backgroundColor: palette.backgroundMain.color,
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _gap,
                _gap,
                _gap,
                Image.asset(
                  'assets/images/dash/ghost1.png',
                  filterQuality: FilterQuality.none,
                  height: 192,
                  width: 192
                ),
                _gap,
                Transform.rotate(
                  angle: -0.1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: const Text(
                      appTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Press Start 2P',
                        fontSize: 32,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                _gap,
                _gap,
                _gap,
                WobblyButton(
                  onPressed: () {
                    GoRouter.of(context).go('/session/1');
                  },
                  child: const Text('Play',
                      style: TextStyle(fontFamily: 'Press Start 2P')),
                ),
                _gap,
                ValueListenableBuilder<bool>(
                  valueListenable: settingsController.audioOn,
                  builder: (context, audioOn, child) {
                    return IconButton(
                      onPressed: () => settingsController.toggleAudioOn(),
                      icon: Icon(audioOn ? Icons.volume_up : Icons.volume_off),
                    );
                  },
                ),
                _gap,
              ],
            ),
        ),
      ),
    );
  }

  static const _gap = SizedBox(height: 40);
}
