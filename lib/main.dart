import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(fBase.initialize());
  GoogleFonts.config.allowRuntimeFetching = false;
  FlutterNativeSplash.remove();
  await Flame.device.fullScreen();
  setupGlobalLogger();
  fixTitlePerm();
  await firstInitialiseSoLoud();
  runApp(const MyGame());
}

class MyGame extends StatelessWidget {
  const MyGame({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      child: MultiProvider(
        providers: <SingleChildWidget>[
          Provider<Palette>(create: (BuildContext context) => Palette()),
          ChangeNotifierProvider<PlayerProgress>(
              create: (BuildContext context) => PlayerProgress()),
          Provider<SettingsController>(
              create: (BuildContext context) => SettingsController()),
          // Set up audio.
          ProxyProvider2<SettingsController, AppLifecycleStateNotifier,
              AudioController>(
            // Ensures that music starts immediately.
            lazy: false,
            create: (BuildContext context) => AudioController(),
            update: (BuildContext context,
                SettingsController settings,
                AppLifecycleStateNotifier lifecycleNotifier,
                AudioController? audio) {
              audio!.attachDependencies(lifecycleNotifier, settings);
              return audio;
            },
            dispose: (BuildContext context, AudioController audio) =>
                audio.dispose(),
          ),
        ],
        child: Builder(builder: (BuildContext context) {
          //context.watch<Palette>();

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
        }),
      ),
    );
  }
}
