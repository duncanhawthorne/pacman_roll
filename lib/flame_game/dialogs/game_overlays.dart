import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../google/google.dart';
import '../../settings/settings.dart';
import '../../style/dialog.dart';
import '../../style/palette.dart';
import '../game_screen.dart';
import '../icons/pacman_icons.dart';
import '../pacman_game.dart';

const double _statusWidgetHeightFactor = 1.0;
const double _widgetSpacing = 8 * _statusWidgetHeightFactor;
const double _clockSpacing = 8 * _statusWidgetHeightFactor;
const double _pacmanOuterSpacing = 8 * _statusWidgetHeightFactor;
const double _pacmanSpacing = 6 * _statusWidgetHeightFactor;
const double pacmanIconSize = 21 * _statusWidgetHeightFactor;
const double gIconSize = pacmanIconSize * 4 / 3;

Widget topOverlayWidget(BuildContext context, PacmanGame game) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: _widgetSpacing,
            children: <Widget>[
              _topLeftWidget(context, game),
              _topRightWidget(context, game)
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _topLeftWidget(BuildContext context, PacmanGame game) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: _widgetSpacing,
    children: <Widget>[
      _mainMenuButtonWidget(context, game),
      _audioOnOffButtonWidget(context, game),
      g.loginLogoutWidget(context, gIconSize, Palette.textColor),
    ],
  );
}

Widget _topRightWidget(BuildContext context, PacmanGame game) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    spacing: _widgetSpacing,
    children: <Widget>[
      _infintyWidget(context, game),
      _livesWidget(context, game),
      _clockWidget(game),
    ],
  );
}

Widget _mainMenuButtonWidget(BuildContext context, PacmanGame game) {
  return IconButton(
    onPressed: () {
      game.playbackMode ? null : game.toggleOverlay(GameScreen.startDialogKey);
    },
    icon: const Icon(Icons.menu, color: Palette.textColor),
  );
}

Widget _livesWidget(BuildContext context, PacmanGame game) {
  return Padding(
    padding: const EdgeInsets.only(
        left: _pacmanOuterSpacing, right: _pacmanOuterSpacing),
    child: ValueListenableBuilder<int>(
      valueListenable: game.numberOfDeathsNotifier,
      builder: (BuildContext context, int value, Widget? child) {
        return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: _pacmanSpacing,
            children: List<Widget>.generate(
                game.level.infLives ? 1 : game.level.maxAllowedDeaths,
                (int index) => animatedPacmanIcon(game, index)));
      },
    ),
  );
}

Widget _infintyWidget(BuildContext context, PacmanGame game) {
  return !game.level.infLives
      ? const SizedBox.shrink()
      : Text("∞", style: TextStyle(color: Palette.pacman.color));
}

Widget _clockWidget(PacmanGame game) {
  return Padding(
    padding: const EdgeInsets.only(left: _clockSpacing, right: _clockSpacing),
    child: StreamBuilder<dynamic>(
      stream: Stream<dynamic>.periodic(const Duration(milliseconds: 100)),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Text(
            (game.stopwatchMilliSeconds / 1000)
                .toStringAsFixed(1)
                .padLeft(4, " "),
            style: textStyleBody);
      },
    ),
  );
}

Widget _audioOnOffButtonWidget(BuildContext context, PacmanGame game) {
  const Color color = Palette.textColor;
  final SettingsController settingsController =
      context.watch<SettingsController>();
  return ValueListenableBuilder<bool>(
    valueListenable: settingsController.audioOn,
    builder: (BuildContext context, bool audioOn, Widget? child) {
      return IconButton(
        onPressed: () {
          settingsController.toggleAudioOn();
          if (settingsController.audioOn.value) {
            game.audioController.playSilence();
          }
        },
        icon: Icon(audioOn ? Icons.volume_up : Icons.volume_off, color: color),
      );
    },
  );
}
