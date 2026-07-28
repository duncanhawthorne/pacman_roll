import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ios_web_touch_override/flutter_ios_web_touch_override.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'app_lifecycle/app_lifecycle.dart';
import 'audio/audio_controller.dart';
import 'firebase/firebase_saves.dart';
import 'player_progress/player_progress.dart';
import 'router.dart';
import 'settings/settings.dart';
import 'style/palette.dart';
import 'utils/constants.dart';
import 'utils/helper.dart';
import 'utils/src/workarounds.dart';

//firebase_options.dart as per direct download from google, not included in repo

/// Entry point of the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeForge2D();
  unawaited(fBase.initialize());
  GoogleFonts.config.allowRuntimeFetching = false;
  FlutterNativeSplash.remove();
  await Flame.device.fullScreen();
  setupGlobalLogger();
  fixTitlePerm();
  await firstInitializeSoLoud();
  blockTouchDefault(true);
  runApp(const MyGame());
}

/// The root widget of the application, responsible for setting up providers,
/// themes, and the router.
class MyGame extends StatelessWidget {
  const MyGame({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          // Re-enforces WebAudio playback and restarts background silence loop on user touch.
          unawaited(AudioController().iosWorkaround.workaround());
        },
        child: MultiProvider(
          providers: <SingleChildWidget>[
            Provider<Palette>(create: (BuildContext context) => Palette()),
            ChangeNotifierProvider<PlayerProgress>(
              create: (BuildContext context) => PlayerProgress(),
            ),
            Provider<SettingsController>(
              create: (BuildContext context) => SettingsController(),
            ),
            // Set up audio as a persistent singleton.
            ProxyProvider2<
              SettingsController,
              AppLifecycleStateNotifier,
              AudioController
            >(
              lazy: false,
              create: (BuildContext context) => AudioController(),
              update:
                  (
                    BuildContext context,
                    SettingsController settings,
                    AppLifecycleStateNotifier lifecycleNotifier,
                    AudioController? audio,
                  ) {
                    audio!.attachDependencies(lifecycleNotifier, settings);
                    return audio;
                  },
              // REMOVED dispose callback so Provider does not destroy singleton instance
            ),
          ],
          child: Builder(
            builder: (BuildContext context) {
              return MaterialApp.router(
                title: appTitle,
                theme: flutterNesTheme().copyWith(
                  scaffoldBackgroundColor: Palette.background.color,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Palette.seed.color,
                    surface: Palette.background.color,
                  ),
                  textTheme: GoogleFonts.pressStart2pTextTheme().apply(
                    bodyColor: Palette.text.color,
                    displayColor: Palette.text.color,
                  ),
                ),
                routeInformationProvider: router.routeInformationProvider,
                routeInformationParser: router.routeInformationParser,
                routerDelegate: router.routerDelegate,
              );
            },
          ),
        ),
      ),
    );
  }
}
