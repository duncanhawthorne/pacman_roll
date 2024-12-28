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
import 'sounds.dart';

final SoLoud soLoud = SoLoud.instance;
const bool _useSoLoudInDebug = true;
final bool _useSoLoud = (kDebugMode && _useSoLoudInDebug) || isiOSWeb;
final bool useAudioPlayers = !_useSoLoud;
final bool detailedAudioLog = _useSoLoud;

class AudioController {
  AudioController() {
    unawaited(_preloadSfx());
  }

  static final Logger _log = Logger('AC');
  SettingsController? _settings;
  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  final Map<SfxType, Future<AudioSource>> _soLoudSources =
      <SfxType, Future<AudioSource>>{};
  final Map<SfxType, Future<SoundHandle>> _soLoudHandles =
      <SfxType, Future<SoundHandle>>{};
  final Map<SfxType, AudioPlayer> _apPlayers = <SfxType, AudioPlayer>{};

  Future<AudioSource> _getSoLoudSound(SfxType type) async {
    await soLoud.initialized;
    assert(soLoud.isInitialized);
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
    if (_useSoLoud && !soLoud.isInitialized) {
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
      if (type != SfxType.ghostsRoamingSiren) {
        _log.fine('Cant play $type: muted.');
      }
      return false;
    }
    final bool soundsOn = _settings?.soundsOn.value ?? true;
    if (!soundsOn) {
      _log.fine('Cant play $type: sounds off');
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
            ..severe(<Object>['Mini crash', type])
            ..severe(<Object?>[e]);
          unawaited(currentPlayer.play(AssetSource(type.filename),
              volume: type.targetVolume));
          rethrow;
        }
        _log.fine(<Object?>["player state", type, currentPlayer.state]);
      } else {
        assert(_useSoLoud);
        await soLoud.initialized;
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
        ..severe(<Object>['Crash', type])
        ..severe(e);
      await dispose();
      rethrow;
    }
  }

  void playSilence() {
    _log.fine("playSilence");
    if (_useSoLoud) {
      playSfx(SfxType.silence, forceUseAudioPlayersOnce: true);
    }
  }

  void playEatGhostAP() {
    _log.fine("playEatGhostAP");
    if (_useSoLoud) {
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
      if (!_apPlayers.containsKey(SfxType.ghostsRoamingSiren)) {
        await playSfx(SfxType.ghostsRoamingSiren);
      }
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
      assert(_useSoLoud);
      await soLoud.initialized;
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
    _log.fine(<Object>["stopSfx", type, soLoud.isInitialized]);
    if (useAudioPlayers) {
      if (_apPlayers.containsKey(type)) {
        unawaited(_apPlayers[type]!.stop());
      }
    } else {
      assert(_useSoLoud);
      if (_soLoudHandles.keys.contains(type)) {
        if (soLoud.isInitialized) {
          await soLoud.stop(await _soLoudHandles[type]!);
        }
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
      assert(_useSoLoud);
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
      playSilence();
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
      assert(_useSoLoud);
      stopAllSounds();
    }
  }

  bool _soLoudNeedsReset = false;
  void _handleAppLifecycle() {
    switch (_lifecycleNotifier!.value) {
      case AppLifecycleState.paused:
        _soLoudNeedsReset = true;
        _log.fine(<String>["Lifecycle paused"]);
      case AppLifecycleState.detached:
        _soLoudNeedsReset = true;
        _log.fine(<String>["Lifecycle detached"]);
      case AppLifecycleState.hidden:
        _soLoudNeedsReset = true;
        _log.fine(<String>["Lifecycle hidden"]);
        stopAllSounds();
      case AppLifecycleState.resumed:
        _log.fine(<String>["Lifecycle resumed"]);
        if (_soLoudNeedsReset) {
          soLoudReset();
          _soLoudNeedsReset = false;
        }
      case AppLifecycleState.inactive:
        _log.fine(<String>["Lifecycle inactive - no op"]);
        // No need to react to this state change.
        break;
    }
  }

  Future<void> _resume() async {
    _log.fine(<String>["Resume"]);
    if (_useSoLoud) {
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
      assert(_useSoLoud);
      for (SfxType type in SfxType.values) {
        unawaited(_getSoLoudSound(type)); //load everything up
      }
    }
  }

  Future<void> dispose() async {
    //don't call manually
    _log.fine("Dispose");
    //_lifecycleNotifier?.removeListener(_handleAppLifecycle);

    if (useAudioPlayers) {
      stopAllSounds();
      for (final AudioPlayer player in _apPlayers.values) {
        unawaited(player.dispose());
      }
      _apPlayers.clear();
    } else {
      assert(_useSoLoud);
      await soLoudReset();
    }
  }

  Future<void> soLoudReset() async {
    if (!_useSoLoud) {
      return;
    }
    _log.fine("soLoudReset");
    stopAllSounds();
    if (soLoud.isInitialized) {
      try {
        await soLoud.disposeAllSources();
        _log.fine("SoLoud sound sources disposed");
      } catch (e) {
        _log
          ..severe("Crash on disposeAllSources")
          ..severe(e);
      }
      soLoud.deinit();
    }
    _soLoudHandles.clear();
    _soLoudSources.clear();
    _log.fine("SoLoud deinit and cleared");
  }
}
