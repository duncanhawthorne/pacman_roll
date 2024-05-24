import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
// ignore: unused_import
import '../audio/sounds.dart';
import '../settings/settings.dart';
import '../style/palette.dart';
import '../style/wobbly_button.dart';
import '../style/responsive_screen.dart';
import '../flame_game/constants.dart';
import '../flame_game/helper.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    setStatusBarColor(palette.backgroundMain.color);
    final settingsController = context.watch<SettingsController>();
    // ignore: unused_local_variable
    final audioController = context.watch<AudioController>();
    //gameRunningFailsafeIndicator = false;
    return Scaffold(
      backgroundColor: palette.backgroundMain.color,
      body: ResponsiveScreen(
        squarishMainArea: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 0.6,
                child: Image.asset(
                  'assets/images/dash/ghost1.png',
                  filterQuality: FilterQuality.none,
                ),
              ),
              //_gap,
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
            ],
          ),
        ),
        rectangularMenuArea: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _gap,
            WobblyButton(
              onPressed: () {
                //audioController.playSfx(SfxType.buttonTap);
                GoRouter.of(context).go('/session/1');
                //setStatusBarColor(palette.flameGameBackground.color);
                //fixTitle();
              },
              child: const Text('Play',
                  style: TextStyle(fontFamily: 'Press Start 2P')),
            ),
            _gap,
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: ValueListenableBuilder<bool>(
                valueListenable: settingsController.audioOn,
                builder: (context, audioOn, child) {
                  return IconButton(
                    onPressed: () => settingsController.toggleAudioOn(),
                    icon: Icon(audioOn ? Icons.volume_up : Icons.volume_off),
                  );
                },
              ),
            ),

            _gap,
            _gap,
            _gap,
            _gap,
            /*
            WobblyButton(
              onPressed: () => GoRouter.of(context).push('/settings'),
              child: const Text('Settings'),
            ),
            _gap,
             */

            _gap,

            //const Text('Built with Flame'),
          ],
        ),
      ),
    );
  }

  static const _gap = SizedBox(height: 10);
}
