import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/settings.dart';
import '../../style/dialog.dart';
import '../../style/palette.dart';
import '../game_screen.dart';
import '../icons/pacman_icons.dart';
import '../pacman_game.dart';

const double _statusWidgetHeightFactor = 1.0;
const _widgetSpacing = 10 * _statusWidgetHeightFactor;
const _clockSpacing = 8 * _statusWidgetHeightFactor;
const _pacmanOuterSpacing = 8 * _statusWidgetHeightFactor;
const _pacmanSpacing = 6 * _statusWidgetHeightFactor;
const pacmanIconSize = 21 * _statusWidgetHeightFactor;
const gIconSize = pacmanIconSize * 4 / 3;

Widget topOverlayWidget(BuildContext context, PacmanGame game) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: _widgetSpacing,
            children: [
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
    children: [
      _mainMenuButtonWidget(context, game),
      _audioOnOffButtonWidget(context, game),
      game.level.isTutorial
          ? SizedBox.shrink()
          : game.playerProgress.g
              .loginLogoutWidget(context, gIconSize, Palette.textColor),
    ],
  );
}

Widget _topRightWidget(BuildContext context, PacmanGame game) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    spacing: _widgetSpacing,
    children: [
      _livesWidget(context, game),
      _clockWidget(game),
    ],
  );
}

Widget _mainMenuButtonWidget(BuildContext context, PacmanGame game) {
  return IconButton(
    onPressed: () {
      game.toggleOverlay(GameScreen.startDialogKey);
    },
    icon: const Icon(Icons.menu, color: Palette.textColor),
  );
}

Widget _livesWidget(BuildContext context, PacmanGame game) {
  return Padding(
    padding: const EdgeInsets.only(
        left: _pacmanOuterSpacing, right: _pacmanOuterSpacing),
    child: ValueListenableBuilder<int>(
      valueListenable: game.world.pacmans.numberOfDeathsNotifier,
      builder: (BuildContext context, int value, Widget? child) {
        return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: _pacmanSpacing,
            children: List.generate(game.level.maxAllowedDeaths,
                (index) => animatedPacmanIcon(game, index)));
      },
    ),
  );
}

Widget _clockWidget(PacmanGame game) {
  return Padding(
    padding: const EdgeInsets.only(left: _clockSpacing, right: _clockSpacing),
    child: StreamBuilder(
      stream: Stream.periodic(const Duration(milliseconds: 100)),
      builder: (context, snapshot) {
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
  const color = Palette.textColor;
  final settingsController = context.watch<SettingsController>();
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
