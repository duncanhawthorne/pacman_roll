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
final bool _useAudioPlayers = !_useSoLoud;
final bool detailedAudioLog = _useSoLoud;
final bool canDoVariableVolume = !_useAudioPlayers || !isiOSWeb; //i.e. true

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
    await soLoudEnsureInitialised();
    if (_soLoudSources.containsKey(type) &&
        soLoud.activeSounds.contains(await _soLoudSources[type])) {
      return _soLoudSources[type]!;
    } else {
      if (_soLoudSources.containsKey(type)) {
        await _soLoudSources.remove(type);
      }
      _log.fine(<Object>["New audio source", type]);
      final Future<AudioSource> currentSound = soLoud.loadAsset(
        'assets/${type.filename}',
        mode: LoadMode.memory, //kIsWeb ? LoadMode.disk : LoadMode.memory,
      );
      _soLoudSources[type] = currentSound;
      return currentSound;
    }
  }

  Future<bool> _canPlay(SfxType type) async {
    await soLoudEnsureInitialised();

    if (!soLoud.isInitialized) {
      _log.severe("canPlay SoLoud not initialised");
      return false;
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
      _log.finest('Can play: $type');
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
      if (_useAudioPlayers || forceUseAudioPlayersOnce) {
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
            ..severe(<Object>['Mini crash on AP', type])
            ..severe(<Object?>[e]);
          unawaited(currentPlayer.play(AssetSource(type.filename),
              volume: type.targetVolume));
          //rethrow;
        }
        _log.fine(<Object?>["player state", type, currentPlayer.state]);
      } else {
        assert(_useSoLoud);
        await soLoudEnsureInitialised();
        assert(type != SfxType.silence);
        final AudioSource sound = await _getSoLoudSound(type);
        final bool retainForStopping =
            //long sounds that might need stopping
            looping || type == SfxType.startMusic || type == SfxType.endMusic;
        if (retainForStopping) {
          if (_soLoudHandles.keys.contains(type) &&
              soLoud.getIsValidVoiceHandle(await _soLoudHandles[type]!)) {
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
      if (_useSoLoud && !forceUseAudioPlayersOnce) {
        await soLoudPowerDownForReset();
      } else {
        //await dispose();
      }
      //rethrow;
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
    const SfxType siren = SfxType.ghostsRoamingSiren;
    if (!(await _canPlay(siren))) {
      return;
    }
    double currentVolume = 0;
    if (_useAudioPlayers) {
      if (!_apPlayers.containsKey(siren)) {
        await playSfx(siren);
      }
      final AudioPlayer sirenPlayer = _apPlayers[siren]!;
      if (sirenPlayer.state != PlayerState.playing) {
        unawaited(playSfx(siren));
        unawaited(sirenPlayer.setVolume(0));
      }
      currentVolume = sirenPlayer.volume;
      final double desiredSirenVolume = _getDesiredSirenVolume(
          normalisedAverageGhostSpeed, currentVolume,
          gradual: gradual);
      unawaited(sirenPlayer.setVolume(desiredSirenVolume));
    } else {
      assert(_useSoLoud);
      await soLoudEnsureInitialised();
      if (!_soLoudHandles.containsKey(siren) ||
          !soLoud.getIsValidVoiceHandle(await _soLoudHandles[siren]!) ||
          soLoud.getPause(await _soLoudHandles[siren]!)) {
        _log.info(<Object>['Restarting ghostsRoamingSiren']);
        await playSfx(siren);
      }
      final SoundHandle handle = await _soLoudHandles[siren]!;
      currentVolume = soLoud.getVolume(handle);
      final double desiredSirenVolume = _getDesiredSirenVolume(
          normalisedAverageGhostSpeed, currentVolume,
          gradual: gradual);
      soLoud.setVolume(handle, desiredSirenVolume);
    }
  }

  Future<void> stopSound(SfxType type) async {
    _log.fine(<Object>["stopSfx", type, soLoud.isInitialized]);
    if (_useAudioPlayers) {
      if (_apPlayers.containsKey(type)) {
        unawaited(_apPlayers[type]!.stop());
      }
    } else {
      assert(_useSoLoud);
      await soLoudEnsureInitialised();
      if (_soLoudHandles.keys.contains(type)) {
        if (soLoud.isInitialized) {
          if (soLoud.getIsValidVoiceHandle(await _soLoudHandles[type]!)) {
            await soLoud.stop(await _soLoudHandles[type]!);
          }
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

  Future<void> stopAllSounds() async {
    _log.fine(<Object>['Stop all sound', _soLoudHandles]);
    if (_useAudioPlayers) {
      for (final AudioPlayer player in _apPlayers.values) {
        unawaited(player.stop());
      }
    } else {
      assert(_useSoLoud);
      await soLoudEnsureInitialised();
      for (SfxType type in _soLoudHandles.keys) {
        unawaited(stopSound(type));
      }
      if (_apPlayers.containsKey(SfxType.silence)) {
        unawaited(_apPlayers[SfxType.silence]!.stop());
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
    if (_useAudioPlayers) {
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
          if (isiOSWeb) {
            _log.info("soLoudReset on iOSWeb lifecycle resume");
            //else soLoud silent stop working
            soLoudPowerDownForReset();
          }
          _soLoudNeedsReset = false;
        }
      case AppLifecycleState.inactive:
        _log.fine(<String>["Lifecycle inactive - no op"]);
        // No need to react to this state change.
        break;
    }
  }

  Future<void> soLoudEnsureInitialised() async {
    if (_useSoLoud) {
      if (!soLoud.isInitialized) {
        _log.fine(<String>["soLoudInitialise wrapper"]);
        //don't soLoud.disposeAllSources here as soLoud not initialised
        clearSources();
        clearHandles();
        await soLoud.init();
        await soLoud.initialized;
        unawaited(_preloadSfx());
      }
    }
  }

  /// Preloads all sound effects.
  Future<void> _preloadSfx() async {
    _log.fine('Preloading sound effects');
    if (_useAudioPlayers) {
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

    if (_useAudioPlayers) {
      unawaited(stopAllSounds());
      for (final AudioPlayer player in _apPlayers.values) {
        unawaited(player.dispose());
      }
      _apPlayers.clear();
    } else {
      assert(_useSoLoud);
      await soLoudPowerDownForReset();
    }
  }

  Future<void> soLoudDisposeAllSources() async {
    if (soLoud.isInitialized) {
      try {
        _log.fine("soLoud.disposeAllSources");
        await soLoud.disposeAllSources();
        clearSources();
      } catch (e) {
        _log
          ..severe("Crash on disposeAllSources")
          ..severe(e);
      }
    } else {
      _log.fine("soLoud.disposeAllSources, but soLoud not initialised");
    }
  }

  void soLoudDeInit() {
    //don't call directly
    _log.fine("soLoudDeInit");
    soLoud.deinit();
  }

  void clearSources() {
    _log.fine("clearSources");
    _soLoudSources.clear();
  }

  void clearHandles() {
    _log.fine("clearHandles");
    _soLoudHandles.clear();
  }

  Future<void> soLoudPowerDownForReset() async {
    if (!_useSoLoud) {
      return;
    }
    _log.fine("soLoudReset");
    unawaited(stopAllSounds());
    if (soLoud.isInitialized) {
      try {
        _log.fine("soLoud.disposeAllSources1");
        await soLoud.disposeAllSources();
      } catch (e) {
        _log
          ..severe("Crash on disposeAllSources")
          ..severe(e);
      }
      soLoudDeInit();
    }
    clearHandles();
    clearSources();
    _log.fine("soLoudReset complete");
  }
}
