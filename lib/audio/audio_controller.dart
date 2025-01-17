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

const bool _useSoLoudInDebug = true;
final bool _platformForSoLoud = ((kDebugMode && _useSoLoudInDebug) || isiOSWeb);
final bool detailedAudioLog = _platformForSoLoud;

bool _soLoudCrashedOnLoad = false;

Future<void> firstInitialiseSoLoud() async {
  try {
    await soLoud.init();
  } catch (e) {
    logGlobal("SoLoud crash, use AP");
    _soLoudCrashedOnLoad = true;
  }
}

final SoLoud soLoud = SoLoud.instance;

final ValueNotifier<bool> flagOnUserInteractionPlaySilence =
    ValueNotifier<bool>(true);
final ValueNotifier<bool> flagOnUserInteractionEnsureSoLoudInitialised =
    ValueNotifier<bool>(false);
final ValueNotifier<bool> flagDeInitOnHidden = ValueNotifier<bool>(true);
final ValueNotifier<bool> flagPlaySilenceOnResume = ValueNotifier<bool>(false);
final ValueNotifier<bool> flagPreLoadSfxOnResume = ValueNotifier<bool>(false);
final ValueNotifier<bool> flagPlaySilenceOnSoLoudEnsureInitialised =
    ValueNotifier<bool>(false);
final ValueNotifier<bool> flagSoLoudInitialisedAsPartOfCanPlayForAPSounds =
    ValueNotifier<bool>(true);

Map<String, ValueNotifier<bool>> checkboxes = <String, ValueNotifier<bool>>{
  "flagOnUserInteractionPlaySilence": flagOnUserInteractionPlaySilence,
  "flagOnUserInteractionEnsureSoLoudInitialised":
      flagOnUserInteractionEnsureSoLoudInitialised,
  "flagDeInitOnHidden": flagDeInitOnHidden,
  "flagPlaySilenceOnResume": flagPlaySilenceOnResume,
  "flagPreLoadSfxOnResume": flagPreLoadSfxOnResume,
  "flagPlaySilenceOnSoLoudEnsureInitialised":
      flagPlaySilenceOnSoLoudEnsureInitialised,
  "flagSoLoudInitialisedAsPartOfCanPlayForAPSounds":
      flagSoLoudInitialisedAsPartOfCanPlayForAPSounds,
};

class AudioController {
  AudioController._() {
    unawaited(_preloadSfx());
  }

  factory AudioController() {
    assert(_instance == null);
    _instance ??= AudioController._();
    return _instance!;
  }

  ///ensures singleton [AudioController]
  static AudioController? _instance;

  final bool _useSoLoud = _platformForSoLoud && !_soLoudCrashedOnLoad;
  late final bool _useAudioPlayers = !_useSoLoud;
  late final bool canDoVariableVolume = !(isiOSWeb && _useAudioPlayers);
  late final bool _soLoudIsUnreliable = _useSoLoud;

  bool get isAudioOn => _settings?.audioOn.value ?? true;

  static final Logger _log = Logger('AC');
  SettingsController? _settings;
  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  final Map<SfxType, Future<AudioSource>> _soLoudSources =
      <SfxType, Future<AudioSource>>{};
  final Map<SfxType, Future<SoundHandle>> _soLoudHandles =
      <SfxType, Future<SoundHandle>>{};
  final Map<SfxType, AudioPlayer> _apPlayers = <SfxType, AudioPlayer>{};

  Future<AudioSource> _getSoLoudSound(SfxType type,
      {bool preload = false}) async {
    await soLoudEnsureInitialised();
    assert(_useSoLoud);
    assert(type != SfxType.silence);
    if (await _soLoudSourceValid(type)) {
      return _soLoudSources[type]!;
    } else {
      if (_soLoudSources.containsKey(type)) {
        await _soLoudSources.remove(type);
      }
      if (!preload) {
        _log.fine("New audio source $type");
      }
      final Future<AudioSource> currentSound = soLoud.loadAsset(
        'assets/${type.filename}',
        mode: LoadMode.memory, //kIsWeb ? LoadMode.disk : LoadMode.memory,
      );
      _soLoudSources[type] = currentSound;
      return currentSound;
    }
  }

  Future<bool> _canPlay(SfxType type,
      {bool forceUseAudioPlayersOnce = false}) async {
    final bool playWithAudioPlayers =
        _useAudioPlayers || forceUseAudioPlayersOnce;

    if (_hiddenBlockPlay()) {
      _log.info("App hidden can't play $type");
      //and don't initialise soLoud
      return false;
    }

    // ignore: dead_code
    if (flagSoLoudInitialisedAsPartOfCanPlayForAPSounds.value ||
        !playWithAudioPlayers) {
      //FIXME requires testing
      await soLoudEnsureInitialised();
      if (_useSoLoud && !soLoud.isInitialized) {
        _log.severe("canPlay SoLoud not initialised, after ensureInitialised");
        return false;
      }
    }

    final bool audioOn = isAudioOn;
    if (!audioOn) {
      if (type != SfxType.ghostsRoamingSiren) {
        //_log.fine('Cant play $type: muted.');
      }
      return false;
    }

    if (type != SfxType.ghostsRoamingSiren) {
      _log.finest('Can play: $type');
    }
    return true;
  }

  Future<void> playSfx(SfxType type,
      {bool forceUseAudioPlayersOnce = false}) async {
    final bool playWithAudioPlayers =
        _useAudioPlayers || forceUseAudioPlayersOnce;
    isAudioOn ? _log.fine('Playing $type') : null;
    if (!(await _canPlay(type,
        forceUseAudioPlayersOnce: forceUseAudioPlayersOnce))) {
      return;
    }
    final bool looping = type == SfxType.ghostsRoamingSiren ||
        //ghostsScared time lasts longer than track length so need to loop
        type == SfxType.ghostsScared ||
        type == SfxType.silence;
    if (playWithAudioPlayers) {
      assert(!forceUseAudioPlayersOnce ||
          type == SfxType.silence ||
          type == SfxType.eatGhost);
      if (type == SfxType.silence && silencePlayingOnAp()) {
        //leave silence repeating
        _log.fine('Silence already playing');
        return;
      }
      if (!_apPlayers.containsKey(type)) {
        _apPlayers[type] = AudioPlayer(playerId: 'sfxPlayer#$type');
      }
      final AudioPlayer currentPlayer = _apPlayers[type]!;
      await currentPlayer
          .setReleaseMode(looping ? ReleaseMode.loop : ReleaseMode.stop);
      await currentPlayer.play(AssetSource(type.filename),
          volume: type.targetVolume);
      await currentPlayer.play(AssetSource(type.filename),
          volume: type.targetVolume);
      _log.finest(() => "Player state $type ${currentPlayer.state}");
    } else {
      try {
        assert(_useSoLoud);
        await soLoudEnsureInitialised();
        assert(type != SfxType.silence);
        final AudioSource sound = await _getSoLoudSound(type);
        final bool retainForStopping =
            //long sounds that might need stopping
            looping || type == SfxType.startMusic || type == SfxType.endMusic;
        if (retainForStopping) {
          if (await _soLoudHandleValid(type)) {
            _log.info(() => "Retained handle, stopping to replay");
            //FIXME is this necessary to stop and then replay with different handle?
            unawaited(soLoud.stop(await _soLoudHandles[type]!));
          }
        }
        final Future<SoundHandle> fHandle = soLoud.play(sound,
            paused: false, looping: looping, volume: type.targetVolume);
        if (retainForStopping) {
          _soLoudHandles[type] = fHandle;
        }
        await fHandle;
      } catch (e) {
        _log
          ..severe('SoLoud play crash, reset $type')
          ..severe(e);
        await soLoudPowerDownForReset();
      }
    }
  }

  Future<void> workaroundiOSSafariAudioOnUserInteraction() async {
    //ideally replaced by ensureSilencePlaying
    //FIXME requires testing
    if (flagOnUserInteractionPlaySilence.value) {
      await playSilence();
    }
    if (flagOnUserInteractionEnsureSoLoudInitialised.value) {
      await soLoudEnsureInitialised();
    }
  }

  bool silencePlayingOnAp() {
    final SfxType type = SfxType.silence;
    return _apPlayers.containsKey(type) &&
        _apPlayers[type]!.state == PlayerState.playing;
  }

  Future<void> playSilence() async {
    //holds open sound channel where soLoud is unreliable
    if (_useSoLoud && _soLoudIsUnreliable) {
      _log.fine("playSilence");
      await playSfx(SfxType.silence, forceUseAudioPlayersOnce: true);
    }
  }

  Future<void> playEatGhostAP() async {
    if (_useSoLoud) {
      _log.fine("playEatGhostAP");
      await playSfx(SfxType.eatGhost, forceUseAudioPlayersOnce: true);
    }
  }

  bool _hiddenBlockPlay() {
    return _lifecycleNotifier == null ||
        _lifecycleNotifier!.value == AppLifecycleState.hidden;
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
        await playSfx(siren);
        //unawaited(sirenPlayer.setVolume(0)); already done in play
      }
      currentVolume = sirenPlayer.volume;
      final double desiredSirenVolume = _getDesiredSirenVolume(
          normalisedAverageGhostSpeed, currentVolume,
          gradual: gradual);
      await sirenPlayer.setVolume(desiredSirenVolume);
    } else {
      assert(_useSoLoud);
      await soLoudEnsureInitialised();
      if (!(await _soLoudHandleValid(siren)) ||
          soLoud.getPause(await _soLoudHandles[siren]!)) {
        _log.info('Restarting ghostsRoamingSiren');
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
    _log.fine("stopSfx $type");
    if (_useAudioPlayers) {
      if (_apPlayers.containsKey(type)) {
        await _apPlayers[type]!.stop();
      }
    } else {
      assert(_useSoLoud);
      await soLoudEnsureInitialised();
      if (await _soLoudHandleValid(type)) {
        final Future<SoundHandle> fHandle = _soLoudHandles[type]!;
        await _soLoudHandles.remove(type); //so play from fresh
        await soLoud.stop(await fHandle);
      }
      if (type == SfxType.silence && _apPlayers.containsKey(SfxType.silence)) {
        await _apPlayers[SfxType.silence]!.stop();
        _log.fine(() => <Object?>[
              'Stop silence direct',
              _apPlayers[SfxType.silence]?.state
            ]);
      }
    }
  }

  Future<void> stopAllSounds() async {
    _log.fine(() => <Object>['Stop all sound', _soLoudHandles.keys]);
    if (_useAudioPlayers) {
      await Future.wait(<Future<void>>[
        for (final AudioPlayer player in _apPlayers.values) player.stop(),
      ]);
    } else {
      assert(_useSoLoud);
      if (_soLoudHandles.isNotEmpty) {
        await soLoudEnsureInitialised();
        await Future.wait(<Future<void>>[
          for (SfxType type in _soLoudHandles.keys) stopSound(type),
        ]);
      }
      if (_apPlayers.containsKey(SfxType.silence)) {
        await _apPlayers[SfxType.silence]!.stop();
        _log.fine(() => <Object?>[
              'Stop silence as part of all',
              _apPlayers[SfxType.silence]?.state
            ]);
      }
    }
  }

  Future<bool> _soLoudHandleValid(SfxType type) async {
    await soLoudEnsureInitialised();
    return _soLoudHandles.keys.contains(type) &&
        soLoud.getIsValidVoiceHandle(await _soLoudHandles[type]!);
  }

  Future<bool> _soLoudSourceValid(SfxType type) async {
    await soLoudEnsureInitialised();
    return _soLoudSources.containsKey(type) &&
        soLoud.activeSounds.contains(await _soLoudSources[type]);
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
  /// Namely, when [SettingsController.audioOn] changes,
  /// the audio controller will act accordingly.
  void _attachSettings(SettingsController settingsController) {
    if (_settings == settingsController) {
      // Already attached to this instance. Nothing to do.
      return;
    }

    // Remove handlers from the old settings controller if present
    final SettingsController? oldSettings = _settings;
    if (oldSettings != null) {
      oldSettings.audioOn.removeListener(_audioOnOffHandler);
    }

    _settings = settingsController;

    // Add handlers to the new settings controller
    settingsController.audioOn.addListener(_audioOnOffHandler);
  }

  void _audioOnOffHandler() {
    _log.fine('audioOn changed to ${_settings!.audioOn.value}');
    if (_settings!.audioOn.value) {
      // All sound just got un-muted. Audio is on.
      workaroundiOSSafariAudioOnUserInteraction();
    } else {
      // All sound just got muted. Audio is off.
      stopAllSounds();
    }
  }

  Future<void> _handleAppLifecycle() async {
    switch (_lifecycleNotifier!.value) {
      case AppLifecycleState.paused:
        _log.fine("Lifecycle paused");
      case AppLifecycleState.detached:
        _log.fine("Lifecycle detached");
      case AppLifecycleState.hidden:
        _log.fine("Lifecycle hidden");
        if (_useSoLoud && _soLoudIsUnreliable) {
          if (flagDeInitOnHidden.value) {
            _log.info("soLoudReset due to unreliable soLoud");
            //else silently stop working
            await soLoudPowerDownForReset();
          }
        } else {
          await stopAllSounds();
        }
      case AppLifecycleState.resumed:
        _log.fine("Lifecycle resumed");
        if (_useSoLoud && _soLoudIsUnreliable) {
          //ideally would preload here to stop preload coinciding with user interaction
          //but soLoudUnreliable workaround fails if so preload here
          if (flagPlaySilenceOnResume.value) {
            await playSilence(); //FIXME requires testing
          }
          if (flagPreLoadSfxOnResume.value) {
            await _preloadSfx(); //FIXME requires testing
          }
        }
      case AppLifecycleState.inactive:
        _log.fine("Lifecycle inactive");
        break;
    }
  }

  Future<void> soLoudEnsureInitialised() async {
    if (_useSoLoud) {
      if (flagPlaySilenceOnSoLoudEnsureInitialised.value) {
        //FIXME requires testing
        if (_soLoudIsUnreliable && !silencePlayingOnAp()) {
          _log.fine("silence not playing, reinitialise");
          await playSilence();
        }
      }
      if (!soLoud.isInitialized) {
        _log.fine("soLoud not initialised, re-initialise");
        //don't soLoud.disposeAllSources here as soLoud not initialised
        assert(!_hiddenBlockPlay());
        clearSources();
        await soLoud.init();
        await soLoud.initialized;
        _log.fine("soLoud now initialised");
        unawaited(_preloadSfx());
      }
    }
  }

  /// Preloads all sound effects.
  Future<void> _preloadSfx() async {
    _log.fine('Preloading sounds');
    if (_hiddenBlockPlay()) {
      return;
    }
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
      await soLoudEnsureInitialised();
      await Future.wait(<Future<AudioSource>>[
        for (SfxType type in SfxType.values)
          if (type != SfxType.silence)
            //load everything up, but silence doesn't go through soLoud
            _getSoLoudSound(type, preload: true)
      ]);
    }
  }

  Future<void> dispose() async {
    //don't call manually
    _log.info("Dispose - don't call manually");
    //_lifecycleNotifier?.removeListener(_handleAppLifecycle);

    if (_useAudioPlayers) {
      await Future.wait(<Future<void>>[
        stopAllSounds(),
        Future.wait(<Future<void>>[
          for (final AudioPlayer player in _apPlayers.values) player.dispose(),
        ]),
      ]); //run all tasks, but ensure all are finished
      _apPlayers.clear();
    } else {
      assert(_useSoLoud);
      await soLoudPowerDownForReset();
      assert(_soLoudSources.isEmpty);
      assert(_soLoudHandles.isEmpty);
    }
  }

  Future<void> soLoudDisposeAllSources() async {
    _log.fine("soLoudDisposeAllSources and clear");
    clearSources();
    assert(_soLoudSources.isEmpty);
    assert(_soLoudHandles.isEmpty);
    if (soLoud.isInitialized) {
      try {
        _log.fine("soLoud.disposeAllSources real");
        await soLoud.disposeAllSources();
      } catch (e) {
        _log
          ..severe("Crash on disposeAllSources")
          ..severe(e);
      }
    } else {
      _log.fine("soLoud.disposeAllSources, but soLoud not initialised");
    }
  }

  void soLoudDeInitOnly() {
    //don't call directly
    _log.fine("soLoudDeInitOnly");
    assert(_soLoudSources.isEmpty);
    assert(_soLoudHandles.isEmpty);
    soLoud.deinit();
  }

  void clearSources() {
    _log.fine("clearSources");
    clearHandles();
    _soLoudSources.clear();
    assert(_soLoudSources.isEmpty);
    assert(_soLoudHandles.isEmpty);
  }

  void clearHandles() {
    _log.fine("clearHandles");
    _soLoudHandles.clear();
    //assert(_soLoudSources.isEmpty);
    assert(_soLoudHandles.isEmpty);
  }

  Future<void> soLoudPowerDownForReset() async {
    if (!_useSoLoud) {
      return;
    }
    assert(_soLoudIsUnreliable);
    _log.fine("soLoudPowerDownForReset");
    await stopAllSounds(); //FIXME is this necessary with disposeAllSources next line
    await soLoudDisposeAllSources(); //FIXME is this necessary with deinit next line (if switch to just deinit, must clear sources separately)
    //clearSources();
    assert(_soLoudSources.isEmpty);
    assert(_soLoudHandles.isEmpty);
    soLoudDeInitOnly();
    _log.fine("soLoudReset complete");
  }
}
