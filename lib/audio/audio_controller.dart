import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import '../app_lifecycle/app_lifecycle.dart';
import '../settings/settings.dart';
import 'sounds.dart';

/// Allows playing music and sound. A facade to `package:audioplayers`.
class AudioController {
  //AudioLogger.logLevel = AudioLogLevel.info;

  /// Creates an instance that plays music and sound.
  ///
  /// Use [polyphony] to configure the number of sound effects (SFX) that can
  /// play at the same time. A [polyphony] of `1` will always only play one
  /// sound (a new sound will stop the previous one). See discussion
  /// of [_sfxPlayers] to learn why this is the case.
  ///
  /// Background music does not count into the [polyphony] limit. Music will
  /// never be overridden by sound effects because that would be silly.
  AudioController({int polyphony = 10})
      : assert(polyphony >= 1),
        _sfxPlayers = <SfxType, AudioPlayer>{
          for (int item
              in List<int>.generate(SfxType.values.length, (int i) => i))
            SfxType.values[item]: AudioPlayer(playerId: 'sfxPlayer#$item')
        } {
    unawaited(_preloadSfx());
  }

  static final Logger _log = Logger('AudioController');

  /// This is a list of [AudioPlayer] instances which are rotated to play
  /// sound effects.
  final Map<SfxType, AudioPlayer> _sfxPlayers;

  final Random _random = Random();

  SettingsController? _settings;

  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  /// Makes sure the audio controller is listening to changes
  /// of both the app lifecycle (e.g. suspended app) and to changes
  /// of settings (e.g. muted sound).
  void attachDependencies(AppLifecycleStateNotifier lifecycleNotifier,
      SettingsController settingsController) {
    _attachLifecycleNotifier(lifecycleNotifier);
    _attachSettings(settingsController);
  }

  void dispose() {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
    _stopAllSound();
    for (final AudioPlayer player in _sfxPlayers.values) {
      player.dispose();
    }
  }

  /// Plays a single sound effect, defined by [type].
  ///
  /// The controller will ignore this call when the attached settings'
  /// [SettingsController.audioOn] is `true` or if its
  /// [SettingsController.soundsOn] is `false`.
  void playSfx(SfxType type) {
    final bool audioOn = _settings?.audioOn.value ?? true;
    if (!audioOn) {
      _log.fine(() => 'Ignoring playing sound ($type) because audio is muted.');
      return;
    }
    final bool soundsOn = _settings?.soundsOn.value ?? true;
    if (!soundsOn) {
      _log.fine(() =>
          'Ignoring playing sound ($type) because sounds are turned off.');
      return;
    }

    _log.fine(() => 'Playing sound: $type');
    final List<String> options = soundTypeToFilename(type);
    final String filename = options[_random.nextInt(options.length)];
    _log.fine(() => '- Chosen filename: $filename');

    final AudioPlayer currentPlayer = _sfxPlayers[type] ?? AudioPlayer();

    //extra code
    if (type == SfxType.ghostsRoamingSiren) {
      // || type == SfxType.ghostsScared
      currentPlayer.setReleaseMode(ReleaseMode.loop);
    } else {
      currentPlayer.setReleaseMode(ReleaseMode.stop);
    }

    currentPlayer.play(AssetSource('sfx/$filename'),
        volume: soundTypeToVolume(type));
  }

  void stopSfx(SfxType type) {
    _sfxPlayers[type]!.stop();
  }

  double getTargetSirenVolume(double averageGhostSpeed) {
    final double tmpSirenVolume = averageGhostSpeed / 30;
    return tmpSirenVolume < 0.01 ? 0 : min(0.4, tmpSirenVolume);
  }

  void setSirenVolume(double normalisedAverageGhostSpeed,
      {bool gradual = false}) {
    final AudioPlayer sirenPlayer = _sfxPlayers[SfxType.ghostsRoamingSiren]!;
    if (sirenPlayer.state != PlayerState.playing) {
      playSfx(SfxType.ghostsRoamingSiren);
      sirenPlayer.setVolume(0);
    }
    final double calcedVolume =
        getTargetSirenVolume(normalisedAverageGhostSpeed);
    final double currentVolume = sirenPlayer.volume / volumeScalar;
    double targetVolume = 0;
    if (gradual) {
      targetVolume = (calcedVolume + currentVolume) / 2;
    } else {
      targetVolume = calcedVolume;
    }
    sirenPlayer.setVolume(targetVolume * volumeScalar);
  }

  void stopAllSfx() {
    _stopAllSound();
  }

  /// Enables the [AudioController] to listen to [AppLifecycleState] events,
  /// and therefore do things like stopping playback when the game
  /// goes into the background.
  void _attachLifecycleNotifier(AppLifecycleStateNotifier lifecycleNotifier) {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);

    lifecycleNotifier.addListener(_handleAppLifecycle);
    _lifecycleNotifier = lifecycleNotifier;
  }

  /// Enables the [AudioController] to track changes to settings.
  /// Namely, when any of [SettingsController.audioOn],
  /// [SettingsController.musicOn] or [SettingsController.soundsOn] changes,
  /// the audio controller will act accordingly.
  void _attachSettings(SettingsController settingsController) {
    if (_settings == settingsController) {
      // Already attached to this instance. Nothing to do.
      return;
    }

    // Remove handlers from the old settings controller if present
    final SettingsController? oldSettings = _settings;
    if (oldSettings != null) {
      oldSettings.audioOn.removeListener(_audioOnHandler);
      oldSettings.soundsOn.removeListener(_soundsOnHandler);
    }

    _settings = settingsController;

    // Add handlers to the new settings controller
    settingsController.audioOn.addListener(_audioOnHandler);
    settingsController.soundsOn.addListener(_soundsOnHandler);
  }

  void _audioOnHandler() {
    _log.fine('audioOn changed to ${_settings!.audioOn.value}');
    if (_settings!.audioOn.value) {
      // All sound just got un-muted. Audio is on.
    } else {
      // All sound just got muted. Audio is off.
      _stopAllSound();
    }
  }

  void _handleAppLifecycle() {
    switch (_lifecycleNotifier!.value) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopAllSound();
      case AppLifecycleState.resumed:
        if (_settings!.audioOn.value && _settings!.musicOn.value) {}
      case AppLifecycleState.inactive:
        // No need to react to this state change.
        break;
    }
  }

  /// Preloads all sound effects.
  Future<void> _preloadSfx() async {
    _log.info('Preloading sound effects');
    // This assumes there is only a limited number of sound effects in the game.
    // If there are hundreds of long sound effect files, it's better
    // to be more selective when preloading.
    await AudioCache.instance.loadAll(SfxType.values
        .expand(soundTypeToFilename)
        .map((String path) => 'sfx/$path')
        .toList());
  }

  void _soundsOnHandler() {
    for (final AudioPlayer player in _sfxPlayers.values) {
      if (player.state == PlayerState.playing) {
        player.stop();
      }
    }
  }

  void _stopAllSound() {
    _log.info('Stopping all sound');
    for (final AudioPlayer player in _sfxPlayers.values) {
      player.stop();
    }
  }
}
