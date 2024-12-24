import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:logging/logging.dart';

import '../app_lifecycle/app_lifecycle.dart';
import '../settings/settings.dart';
import '../utils/helper.dart';
import 'sounds.dart';

final SoLoud soLoud = SoLoud.instance;

/// Allows playing music and sound. A facade to `package:audioplayers`.
class AudioController {
  //AudioLogger.logLevel = AudioLogLevel.info;

  /// Creates an instance that plays music and sound.
  ///
  /// Use [polyphony] to configure the number of sound effects (SFX) that can
  /// play at the same time. A [polyphony] of `1` will always only play one
  /// sound (a new sound will stop the previous one). See discussion
  /// of [_apPlayers] to learn why this is the case.
  ///
  /// Background music does not count into the [polyphony] limit. Music will
  /// never be overridden by sound effects because that would be silly.
  AudioController({int polyphony = 10})
      : assert(polyphony >= 1),
        _apPlayers = !ap
            ? <SfxType, AudioPlayer>{}
            : <SfxType, AudioPlayer>{
                for (int item
                    in List<int>.generate(SfxType.values.length, (int i) => i))
                  SfxType.values[item]: AudioPlayer(playerId: 'sfxPlayer#$item')
              } {
    unawaited(_preloadSfx());
  }

  static final Logger _log = Logger('AudioController');

  /// This is a list of [AudioPlayer] instances which are rotated to play
  /// sound effects.
  final Map<SfxType, Future<AudioSource>> _soLoudSources =
      <SfxType, Future<AudioSource>>{};
  final Map<SfxType, Future<SoundHandle>> _soLoudHandles =
      <SfxType, Future<SoundHandle>>{};
  final Map<SfxType, AudioPlayer> _apPlayers;

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
    if (ap) {
      for (final AudioPlayer player in _apPlayers.values) {
        player.dispose();
      }
    }
  }

  String _getFilename(SfxType type) {
    final List<String> options = soundTypeToFilename(type);
    final String filename = options[_random.nextInt(options.length)];
    return "sfx/$filename";
  }

  Future<AudioSource> _getSoLoudSound(SfxType type) async {
    if (_soLoudSources.containsKey(type)) {
      return _soLoudSources[type]!;
    } else {
      final Future<AudioSource> currentSound = soLoud.loadAsset(
        'assets/${_getFilename(type)}',
        mode: LoadMode.memory, //kIsWeb ? LoadMode.disk : LoadMode.memory,
      );
      _soLoudSources[type] = currentSound;
      return currentSound;
    }
  }

  bool _canPlay(SfxType type) {
    if (!ap && !soLoud.isInitialized) {
      debug("not initialised");
      return false;
    }

    /// The controller will ignore this call when the attached settings'
    /// [SettingsController.audioOn] is `true` or if its
    /// [SettingsController.soundsOn] is `false`.

    final bool audioOn = _settings?.audioOn.value ?? true;
    if (!audioOn) {
      _log.fine(() => 'Ignoring playing sound ($type) because audio is muted.');
      return false;
    }
    final bool soundsOn = _settings?.soundsOn.value ?? true;
    if (!soundsOn) {
      _log.fine(() =>
          'Ignoring playing sound ($type) because sounds are turned off.');
      return false;
    }
    _log.fine(() => 'Playing sound: $type');
    return true;
  }

  Future<void> playSfx(SfxType type) async {
    if (!_canPlay(type)) {
      return;
    }
    final bool looping = type == SfxType.ghostsRoamingSiren ||
        //ghostsScared time lasts longer than track length so need to loop
        type == SfxType.ghostsScared;

    if (ap) {
      final AudioPlayer currentPlayer = _apPlayers[type] ?? AudioPlayer();
      unawaited(currentPlayer
          .setReleaseMode(looping ? ReleaseMode.loop : ReleaseMode.stop));
      unawaited(currentPlayer.play(AssetSource(_getFilename(type)),
          volume: soundTypeToVolume(type)));
    } else {
      final AudioSource sound = await _getSoLoudSound(type);
      final bool retainForStopping =
          //long sounds that might need stopping
          looping || type == SfxType.startMusic || type == SfxType.endMusic;
      if (retainForStopping) {
        if (_soLoudHandles.keys.contains(type)) {
          unawaited(soLoud.stop(await _soLoudHandles[type]!));
        }
      }
      final Future<SoundHandle> fHandle = soLoud.play(sound,
          paused: false, looping: looping, volume: soundTypeToVolume(type));
      if (retainForStopping) {
        _soLoudHandles[type] = fHandle;
      }
      await fHandle;
    }
  }

  Future<void> stopSfx(SfxType type) async {
    if (ap) {
      unawaited(_apPlayers[type]!.stop());
    } else {
      if (_soLoudHandles.keys.contains(type)) {
        await soLoud.stop(await _soLoudHandles[type]!);
        unawaited(
            _soLoudHandles.remove(type)); //remove so play from fresh after stop
      }
    }
  }

  double _getUltimateTargetSirenVolume(double normalisedAverageGhostSpeed) {
    final double tmpSirenVolume = normalisedAverageGhostSpeed / 30 * 2.5;
    return min(1, tmpSirenVolume) * volumeScalar;
  }

  double _getDesiredSirenVolume(
      double normalisedAverageGhostSpeed, double currentVolume,
      {bool gradual = false}) {
    double targetVolume =
        _getUltimateTargetSirenVolume(normalisedAverageGhostSpeed);
    if (gradual) {
      targetVolume = (targetVolume + currentVolume) / 2;
    }
    targetVolume = targetVolume < 0.01 * volumeScalar ? 0 : targetVolume;
    return targetVolume;
  }

  Future<void> setSirenVolume(double normalisedAverageGhostSpeed,
      {bool gradual = false}) async {
    double currentVolume = 0;
    if (ap) {
      final AudioPlayer sirenPlayer = _apPlayers[SfxType.ghostsRoamingSiren]!;
      if (sirenPlayer.state != PlayerState.playing) {
        unawaited(playSfx(SfxType.ghostsRoamingSiren));
        unawaited(sirenPlayer.setVolume(0));
      }
      currentVolume = sirenPlayer.volume;
      final double desiredSirenVolume = _getDesiredSirenVolume(
          normalisedAverageGhostSpeed, currentVolume,
          gradual: gradual);
      unawaited(sirenPlayer.setVolume(desiredSirenVolume));
    } else {
      if (!_soLoudHandles.containsKey(SfxType.ghostsRoamingSiren) ||
          soLoud.getPause(await _soLoudHandles[SfxType.ghostsRoamingSiren]!)) {
        await playSfx(SfxType.ghostsRoamingSiren);
      }
      final SoundHandle handle =
          await _soLoudHandles[SfxType.ghostsRoamingSiren]!;
      currentVolume = soLoud.getVolume(handle);
      final double desiredSirenVolume = _getDesiredSirenVolume(
          normalisedAverageGhostSpeed, currentVolume,
          gradual: gradual);
      soLoud.setVolume(handle, desiredSirenVolume);
    }
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
    if (ap) {
      // This assumes there is only a limited number of sound effects in the game.
      // If there are hundreds of long sound effect files, it's better
      // to be more selective when preloading.
      await AudioCache.instance.loadAll(SfxType.values
          .expand(soundTypeToFilename)
          .map((String path) => 'sfx/$path')
          .toList());
    } else {
      for (SfxType type in SfxType.values) {
        unawaited(_getSoLoudSound(type)); //load everything up
      }
    }
  }

  void _soundsOnHandler() {
    if (ap) {
      for (final AudioPlayer player in _apPlayers.values) {
        if (player.state == PlayerState.playing) {
          player.stop();
        }
      }
    } else {
      _stopAllSound();
    }
  }

  void _stopAllSound() {
    _log.info('Stopping all sound');
    if (ap) {
      for (final AudioPlayer player in _apPlayers.values) {
        player.stop();
      }
    } else {
      for (SfxType type in _soLoudHandles.keys) {
        stopSfx(type);
      }
    }
  }
}

final bool _iOSWeb = defaultTargetPlatform == TargetPlatform.iOS && kIsWeb;
final bool ap = !kDebugMode && !_iOSWeb;
