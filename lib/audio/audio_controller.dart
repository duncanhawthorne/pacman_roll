import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:logging/logging.dart';

import '../app_lifecycle/app_lifecycle.dart';
import '../settings/settings.dart';
import '../utils/constants.dart';
import '../utils/helper.dart';
import 'sounds.dart';

final SoLoud soLoud = SoLoud.instance;
final bool useAudioPlayers = !kDebugMode && !isiOSWeb;
final bool detailedAudioLog = isiOSWeb || kDebugMode;

class AudioController {
  AudioController() {
    unawaited(_preloadSfx());
    _setupLogger();
  }

  static final Logger _log = Logger('AudioController');
  SettingsController? _settings;
  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  final Map<SfxType, Future<AudioSource>> _soLoudSources =
      <SfxType, Future<AudioSource>>{};
  final Map<SfxType, Future<SoundHandle>> _soLoudHandles =
      <SfxType, Future<SoundHandle>>{};
  final Map<SfxType, AudioPlayer> _apPlayers = <SfxType, AudioPlayer>{};

  Future<AudioSource> _getSoLoudSound(SfxType type) async {
    if (_soLoudSources.containsKey(type)) {
      return _soLoudSources[type]!;
    } else {
      final Future<AudioSource> currentSound = soLoud.loadAsset(
        'assets/${type.filename}',
        mode: LoadMode.memory, //kIsWeb ? LoadMode.disk : LoadMode.memory,
      );
      _soLoudSources[type] = currentSound;
      return currentSound;
    }
  }

  Future<bool> _canPlay(SfxType type) async {
    if (!useAudioPlayers && !soLoud.isInitialized) {
      _log.info("SoLoud not initialised");
      await _resume();
      _log.info(<Object>["SoLoud initialised?", soLoud.isInitialized]);
      if (!soLoud.isInitialized) {
        return false;
      }
    }

    /// The controller will ignore this call when the attached settings'
    /// [SettingsController.audioOn] is `true` or if its
    /// [SettingsController.soundsOn] is `false`.

    final bool audioOn = _settings?.audioOn.value ?? true;
    if (!audioOn) {
      _log.fine('Ignoring playing ($type) because audio is muted.');
      return false;
    }
    final bool soundsOn = _settings?.soundsOn.value ?? true;
    if (!soundsOn) {
      _log.fine('Ignoring playing ($type) because sounds are turned off.');
      return false;
    }
    if (type != SfxType.ghostsRoamingSiren) {
      _log.fine('Can play: $type');
    }
    return true;
  }

  Future<void> playSfx(SfxType type,
      {bool forceUseAudioPlayersOnce = false}) async {
    try {
      _log.fine(<Object>['Playing $type']);
      if (!(await _canPlay(type))) {
        return;
      }
      final bool looping = type == SfxType.ghostsRoamingSiren ||
          //ghostsScared time lasts longer than track length so need to loop
          type == SfxType.ghostsScared ||
          type == SfxType.silence;
      if (useAudioPlayers || forceUseAudioPlayersOnce) {
        assert(!forceUseAudioPlayersOnce ||
            type == SfxType.silence ||
            type == SfxType.eatGhost);
        if (type == SfxType.silence &&
            _apPlayers.containsKey(type) &&
            _apPlayers[type]!.state == PlayerState.playing) {
          //leave silence repeating
          _log.fine(<Object>['Silence already playing']);
          return;
        }
        if (!_apPlayers.containsKey(type)) {
          _apPlayers[type] = AudioPlayer(playerId: 'sfxPlayer#$type');
        }
        final AudioPlayer currentPlayer = _apPlayers[type]!;
        await currentPlayer
            .setReleaseMode(looping ? ReleaseMode.loop : ReleaseMode.stop);
        try {
          await currentPlayer.play(AssetSource(type.filename),
              volume: type.targetVolume);
        } catch (e) {
          _log
            ..severe(<Object>['Mini crash'])
            ..severe(<Object?>[e]);
          unawaited(currentPlayer.play(AssetSource(type.filename),
              volume: type.targetVolume));
        }
        _log.fine(<Object?>["player state", type, currentPlayer.state]);
      } else {
        assert(type != SfxType.silence);
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
            paused: false, looping: looping, volume: type.targetVolume);
        if (retainForStopping) {
          _soLoudHandles[type] = fHandle;
        }
        await fHandle;
      }
    } catch (e) {
      _log
        ..severe(<Object>['Crash'])
        ..severe(e);
      await dispose();
    }
  }

  void playSilence() {
    _log.fine("playSilence");
    if (!useAudioPlayers && (isiOSWeb || kDebugMode)) {
      playSfx(SfxType.silence, forceUseAudioPlayersOnce: true);
    }
  }

  void playEatGhostAP() {
    _log.fine("playEatGhostAP");
    if (!useAudioPlayers && (isiOSWeb || kDebugMode)) {
      playSfx(SfxType.eatGhost, forceUseAudioPlayersOnce: true);
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
    if (!(await _canPlay(SfxType.ghostsRoamingSiren))) {
      return;
    }
    double currentVolume = 0;
    if (useAudioPlayers) {
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
        _log
          ..info(<Object>[
            'Restarting ghostsRoamingSiren',
          ])
          ..info(<Object>[
            "handle?",
            _soLoudHandles.containsKey(SfxType.ghostsRoamingSiren),
          ])
          ..info(<Object>[
            "paused?",
            _soLoudHandles.containsKey(SfxType.ghostsRoamingSiren)
                ? soLoud
                    .getPause(await _soLoudHandles[SfxType.ghostsRoamingSiren]!)
                : "n/a"
          ]);
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

  Future<void> stopSound(SfxType type) async {
    _log.fine(<Object>["stopSfx", type]);
    if (useAudioPlayers) {
      unawaited(_apPlayers[type]!.stop());
    } else {
      if (_soLoudHandles.keys.contains(type)) {
        await soLoud.stop(await _soLoudHandles[type]!);
        unawaited(
            _soLoudHandles.remove(type)); //remove so play from fresh after stop
      }
      if (type == SfxType.silence && _apPlayers.containsKey(SfxType.silence)) {
        await _apPlayers[SfxType.silence]!.stop();
        _log.fine(<Object>[
          'Stop silence direct',
          _apPlayers[SfxType.silence]!.state
        ]);
      }
    }
  }

  void stopAllSounds() {
    _log.fine(<Object>['Stop all sound', _soLoudHandles]);
    if (useAudioPlayers) {
      for (final AudioPlayer player in _apPlayers.values) {
        player.stop();
      }
    } else {
      for (SfxType type in _soLoudHandles.keys) {
        stopSound(type);
      }
      if (_apPlayers.containsKey(SfxType.silence)) {
        _apPlayers[SfxType.silence]!.stop();
        _log.fine(<Object>[
          'Stop silence as part of all',
          _apPlayers[SfxType.silence]!.state
        ]);
      }
    }
  }

  final List<String> debugLogList = <String>[""];
  final ValueNotifier<int> debugLogListIterator = ValueNotifier<int>(0);
  void _setupLogger() {
    if (detailedAudioLog) {
      Logger.root.level = Level.ALL;
    }
    _log.onRecord.listen((LogRecord record) {
      debug('AC ${record.message}');
      debugLogList.add(record.message);
      debugLogListIterator.value += 1;
    });
  }

  /// Makes sure the audio controller is listening to changes
  /// of both the app lifecycle (e.g. suspended app) and to changes
  /// of settings (e.g. muted sound).
  void attachDependencies(AppLifecycleStateNotifier lifecycleNotifier,
      SettingsController settingsController) {
    _attachLifecycleNotifier(lifecycleNotifier);
    _attachSettings(settingsController);
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
      stopAllSounds();
    }
  }

  void _soundsOnHandler() {
    if (useAudioPlayers) {
      for (final AudioPlayer player in _apPlayers.values) {
        if (player.state == PlayerState.playing) {
          player.stop();
        }
      }
    } else {
      stopAllSounds();
    }
  }

  void _handleAppLifecycle() {
    switch (_lifecycleNotifier!.value) {
      case AppLifecycleState.paused:
        _log.fine(<String>["Lifecycle paused - no op"]);
      case AppLifecycleState.detached:
        _log.fine(<String>["Lifecycle detached - no op"]);
      case AppLifecycleState.hidden:
        _log.fine(<String>["Lifecycle hidden - no op"]);
      //stopAllSounds();
      case AppLifecycleState.resumed:
        _log.fine(<String>["Lifecycle resumed - no op"]);
      //dispose();
      //_resume();
      case AppLifecycleState.inactive:
        _log.fine(<String>["Lifecycle inactive - no op"]);
        // No need to react to this state change.
        break;
    }
  }

  Future<void> _resume() async {
    _log.fine(<String>["Resume"]);
    if (!useAudioPlayers) {
      if (!soLoud.isInitialized) {
        await soLoud.init();
      }
    }
  }

  /// Preloads all sound effects.
  Future<void> _preloadSfx() async {
    _log.fine('Preloading sound effects');
    if (useAudioPlayers) {
      // This assumes there is only a limited number of sound effects in the game.
      // If there are hundreds of long sound effect files, it's better
      // to be more selective when preloading.
      await AudioCache.instance.loadAll(
          SfxType.values.map((SfxType type) => type.filename).toList());
      for (SfxType type in SfxType.values) {
        if (!_apPlayers.containsKey(type)) {
          _apPlayers[type] = AudioPlayer(playerId: 'sfxPlayer#$type');
        }
      }
    } else {
      for (SfxType type in SfxType.values) {
        unawaited(_getSoLoudSound(type)); //load everything up
      }
    }
  }

  Future<void> dispose() async {
    //don't call manually
    _log.fine("Dispose");
    //_lifecycleNotifier?.removeListener(_handleAppLifecycle);
    stopAllSounds();
    if (useAudioPlayers) {
      for (final AudioPlayer player in _apPlayers.values) {
        unawaited(player.dispose());
      }
    } else {
      if (soLoud.isInitialized) {
        try {
          await soLoud.disposeAllSources();
          _log.fine("SoLoud sound sources disposed");
        } catch (e) {
          _log
            ..severe("Crash on disposeAllSources")
            ..severe(e);
        }
      }
      soLoud.deinit();
      _soLoudHandles.clear();
      _soLoudSources.clear();
      _log.fine("SoLoud deinit and cleared");
    }
  }
}
