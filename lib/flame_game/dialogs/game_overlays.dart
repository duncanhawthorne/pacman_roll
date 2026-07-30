import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../google/google.dart';
import '../../settings/settings.dart';
import '../../style/dialog.dart';
import '../../style/palette.dart';
import '../../utils/constants.dart';
import '../../utils/helper.dart';
import '../components/lap_angle.dart';
import '../custom_game.dart';
import '../game_screen.dart';
import '../icons/pacman_icons.dart';

const double _statusWidgetHeightFactor = 1.0;
const double _widgetSpacing = 8 * _statusWidgetHeightFactor;
const double _clockSpacing = 8 * _statusWidgetHeightFactor;
const double _pacmanOuterSpacing = 8 * _statusWidgetHeightFactor;
const double _pacmanSpacing = 6 * _statusWidgetHeightFactor;
const double pacmanIconSize = 21 * _statusWidgetHeightFactor;
const double gIconSize = pacmanIconSize * 4 / 3;

/// Top-level status widget displayed over the game.
Widget topOverlayWidget(BuildContext context, CustomGame game) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: ValueListenableBuilder<bool>(
        valueListenable: g.loggingInProcess,
        builder: (BuildContext context, bool value, Widget? child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: _widgetSpacing,
                children: <Widget>[
                  _topLeftWidget(context, game),
                  _topRightWidget(context, game),
                ],
              ),
              Visibility(
                visible: g.loggingInProcess.value,
                maintainState: false,
                child: g.gWidget,
              ),
            ],
          );
        },
      ),
    ),
  );
}

Widget _topLeftWidget(BuildContext context, CustomGame game) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: _widgetSpacing,
    children: <Widget>[
      _mainMenuButtonWidget(context, game),
      _audioOnOffButtonWidget(context, game),
      g.loginLogoutWidget(context, gIconSize, Palette.textColor),
      if (kIsWeb && _isDesktop) _mouseLockButtonWidget(context, game),
    ],
  );
}

Widget _topRightWidget(BuildContext context, CustomGame game) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    spacing: _widgetSpacing,
    children: <Widget>[
      _infintyWidget(context, game),
      _livesWidget(context, game),
      enableRotationRaceMode ? _raceProgressWidget(game) : _clockWidget(game),
    ],
  );
}

Widget _mainMenuButtonWidget(BuildContext context, CustomGame game) {
  return IconButton(
    onPressed: () {
      game.overlays.activeOverlays.contains(GameScreen.beginDialogKey)
          ? null
          : game.dialogs.toggle(GameScreen.startDialogKey);
    },
    icon: const Icon(Icons.menu, color: Palette.textColor),
  );
}

Widget _livesWidget(BuildContext context, CustomGame game) {
  return Padding(
    padding: const EdgeInsets.only(
      left: _pacmanOuterSpacing,
      right: _pacmanOuterSpacing,
    ),
    child: ValueListenableBuilder<int>(
      valueListenable: game.session.numberOfDeathsNotifier,
      builder: (BuildContext context, int value, Widget? child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: _pacmanSpacing,
          children: List<Widget>.generate(
            game.level.infLives ? 1 : game.level.maxAllowedDeaths,
            (int index) => animatedPacmanIcon(game, index),
          ),
        );
      },
    ),
  );
}

Widget _infintyWidget(BuildContext context, CustomGame game) {
  return !game.level.infLives
      ? const SizedBox.shrink()
      : Text("∞", style: TextStyle(color: Palette.pacman.color));
}

// ignore: unused_element
Widget _clockWidget(CustomGame game) {
  return GestureDetector(
    onLongPress: () {
      if (detailedAudioLog) {
        game.dialogs.toggle(GameScreen.debugDialogKey);
      }
    },
    child: Padding(
      padding: const EdgeInsets.only(left: _clockSpacing, right: _clockSpacing),
      child: StreamBuilder<int>(
        stream: Stream<int>.periodic(
          const Duration(milliseconds: 100),
          (int i) => i,
        ),
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          return Text(
            (game.session.stopwatchMilliSeconds / 1000)
                .toStringAsFixed(1)
                .padLeft(4, " "),
            style: textStyleBody,
          );
        },
      ),
    ),
  );
}

// ignore: unused_element
Widget _raceProgressWidget(CustomGame game) {
  return GestureDetector(
    onLongPress: () {
      if (detailedAudioLog) {
        game.dialogs.toggle(GameScreen.debugDialogKey);
      }
    },
    child: Padding(
      padding: const EdgeInsets.only(left: _clockSpacing, right: _clockSpacing),
      child: StreamBuilder<int>(
        stream: Stream<int>.periodic(
          const Duration(milliseconds: 100),
          (int i) => i,
        ),
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          return Text(
            getRaceProgress(game.world).toStringAsFixed(2).padLeft(4, " "),
            style: textStyleBody,
          );
        },
      ),
    ),
  );
}

Widget _audioOnOffButtonWidget(BuildContext context, CustomGame game) {
  const Color color = Palette.textColor;
  final SettingsController settingsController = context
      .watch<SettingsController>();
  return ValueListenableBuilder<bool>(
    valueListenable: settingsController.audioOn,
    builder: (BuildContext context, bool audioOn, Widget? child) {
      return IconButton(
        onPressed: () {
          settingsController.toggleAudioOn();
        },
        icon: Icon(audioOn ? Icons.volume_up : Icons.volume_off, color: color),
      );
    },
  );
}

Widget _mouseLockButtonWidget(BuildContext context, CustomGame game) {
  const Color color = Palette.textColor;
  return IconButton(
    onPressed: () {
      game.world.mouseMove.requestPointerLockIfAllowed();
    },
    icon: const Icon(Icons.mouse, color: color),
  );
}

bool get _isDesktop {
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}
