import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:logging/logging.dart';

import '../app_lifecycle/app_lifecycle.dart';
import '../settings/settings.dart';
import '../utils/constants.dart';
import '../utils/helper.dart';
import 'ios_audio.dart';
import 'siren_audio.dart';
import 'sounds.dart';

const bool isAudioSystemEnabled = true;

final bool detailedAudioLog = true; //FIXME disable

/// Performs the initial setup of the SoLoud audio engine.
Future<void> firstInitialiseSoLoud() async {
  if (!isAudioSystemEnabled) {
    return;
  }
  try {
    await soLoud.init();
  } catch (e) {
    logGlobal("SoLoud crash");
  }
}

/// Global instance of the SoLoud audio engine.
final SoLoud soLoud = SoLoud.instance;

/// Global audio controller that manages sound effects and music.
class AudioController {
  AudioController._() {
    unawaited(_preloadSfx());
  }

  /// Returns the singleton instance of the [AudioController].
  factory AudioController() {
    assert(_instance == null);
    _instance ??= AudioController._();
    return _instance!;
  }

  late final SirenAudioController siren = SirenAudioController(this);
  late final IosWorkaround iosWorkaround = IosWorkaround(this);

  ///ensures singleton [AudioController]
  static AudioController? _instance;

  late final bool soLoudIsUnreliable = isiOSWeb;

  SoundHandle? getHandle(SfxType type) => _soLoudHandles[type];

  /// Checks if audio is enabled and not muted.
  bool get isAudioOn =>
      isAudioSystemEnabled && (_settings?.audioOn.value ?? true);

  static final Logger _log = Logger('AC');
  SettingsController? _settings;
  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  /// Caches for SoLoud audio sources, handles, and AudioPlayers instances.
  final Map<SfxType, Future<AudioSource>> _soLoudSources =
      <SfxType, Future<AudioSource>>{};
  final Map<SfxType, SoundHandle> _soLoudHandles = <SfxType, SoundHandle>{};

  /// Loads or retrieves a SoLoud sound source.
  Future<AudioSource> _getSoLoudSound(
    SfxType type, {
    bool preload = false,
  }) async {
    await soLoudEnsureInitialised();
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

  /// Validates if a sound can be played based on current settings and state.
  Future<bool> canPlay(SfxType type) async {
    if (!isAudioSystemEnabled) {
      return false;
    }

    if (_hiddenBlockPlay()) {
      _log.info("App hidden can't play $type");
      //and don't initialise soLoud
      return false;
    }

    //FIXME requires testing
    await soLoudEnsureInitialised();
    if (!soLoud.isInitialized) {
      _log.severe("canPlay SoLoud not initialised, after ensureInitialised");
      return false;
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

  /// Plays a specific sound effect.
  Future<void> playSfx(SfxType type) async {
    if (!isAudioSystemEnabled) {
      return;
    }
    if (isAudioOn) _log.fine('Playing $type');
    if (!(await canPlay(type))) {
      return;
    }
    final bool looping =
        type == SfxType.ghostsRoamingSiren ||
        //ghostsScared time lasts longer than track length so need to loop
        type == SfxType.ghostsScared;
    try {
      await soLoudEnsureInitialised();
      final AudioSource sound = await _getSoLoudSound(type);
      final bool retainForStopping =
          //long sounds that might need stopping
          looping || type == SfxType.startMusic || type == SfxType.endMusic;
      if (retainForStopping) {
        if (await soLoudHandleValid(type)) {
          _log.info(() => "Retained handle, stopping to replay");
          //FIXME is this necessary to stop and then replay with different handle?
          unawaited(soLoud.stop(_soLoudHandles[type]!));
        }
      }
      final SoundHandle fHandle = soLoud.play(
        sound,
        paused: false,
        looping: looping,
        volume: type.targetVolume,
      );
      if (retainForStopping) {
        _soLoudHandles[type] = fHandle;
      }
      fHandle; //previously awaited
    } catch (e) {
      _log
        ..severe('SoLoud play crash, reset $type')
        ..severe(e);
      await _soLoudPowerDownForReset();
    }
  }

  /// Checks if the app's current lifecycle state should block audio playback.
  bool _hiddenBlockPlay() {
    return _lifecycleNotifier == null ||
        _lifecycleNotifier!.value == AppLifecycleState.hidden;
  }

  /// Stops a specific sound effect if it is playing.
  Future<void> stopSound(SfxType type) async {
    if (!isAudioSystemEnabled) {
      return;
    }
    assert(type != SfxType.silence);
    if (isAudioOn) _log.fine("stopSfx $type");
    await soLoudEnsureInitialised();
    if (await soLoudHandleValid(type)) {
      final SoundHandle fHandle = _soLoudHandles[type]!;
      _soLoudHandles.remove(type); //so play from fresh
      await soLoud.stop(fHandle);
    }
  }

  /// Stops all currently playing sounds.
  Future<void> stopAllSounds() async {
    if (!isAudioSystemEnabled) {
      return;
    }
    _log.fine(() => <Object>['Stop all sound', _soLoudHandles.keys]);
    if (_soLoudHandles.isNotEmpty) {
      await soLoudEnsureInitialised();
      await Future.wait(<Future<void>>[
        for (SfxType type in _soLoudHandles.keys) stopSound(type),
      ]);
    }
    await iosWorkaround.stopAllSounds();
  }

  Future<bool> soLoudHandleValid(SfxType type) async {
    await soLoudEnsureInitialised();
    return _soLoudHandles.keys.contains(type) &&
        soLoud.getIsValidVoiceHandle(_soLoudHandles[type]!);
  }

  Future<bool> _soLoudSourceValid(SfxType type) async {
    await soLoudEnsureInitialised();
    return _soLoudSources.containsKey(type) &&
        soLoud.activeSounds.contains(await _soLoudSources[type]);
  }

  /// Makes sure the audio controller is listening to changes
  /// of both the app lifecycle (e.g. suspended app) and to changes
  /// of settings (e.g. muted sound).
  /// Attaches external dependencies for lifecycle and settings tracking.
  void attachDependencies(
    AppLifecycleStateNotifier lifecycleNotifier,
    SettingsController settingsController,
  ) {
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
      iosWorkaround.workaround();
    } else {
      // All sound just got muted. Audio is off.
      stopAllSounds();
    }
  }

  Future<void> _handleAppLifecycle() async {
    if (!isAudioSystemEnabled) {
      return;
    }
    switch (_lifecycleNotifier!.value) {
      case AppLifecycleState.paused:
        _log.fine("Lifecycle paused");
      case AppLifecycleState.detached:
        _log.fine("Lifecycle detached");
      case AppLifecycleState.hidden:
        _log.fine("Lifecycle hidden");
        if (soLoudIsUnreliable) {
          _log.info("soLoudReset due to unreliable soLoud");
          //else silently stop working
          await _soLoudPowerDownForReset();
        } else {
          await stopAllSounds();
        }
      case AppLifecycleState.resumed:
        _log.fine("Lifecycle resumed");
        if (soLoudIsUnreliable) {
          //ideally would preload here to stop preload coinciding with user interaction
          //but soLoudUnreliable workaround fails if so preload here
        }
      case AppLifecycleState.inactive:
        _log.fine("Lifecycle inactive");
        break;
    }
  }

  /// Ensures that the SoLoud engine is initialized and ready for use.
  Future<void> soLoudEnsureInitialised() async {
    if (!isAudioSystemEnabled) {
      return;
    }
    if (!soLoud.isInitialized) {
      _log.fine("soLoud not initialised, re-initialise");
      //don't soLoud.disposeAllSources here as soLoud not initialised
      assert(!_hiddenBlockPlay());
      _clearSources();
      await soLoud.init();
      assert(soLoud.isInitialized);
      _log.fine("soLoud now initialised");
      unawaited(_preloadSfx());
    }
  }

  /// Preloads all sound effects.
  Future<void> _preloadSfx() async {
    _log.fine('Preloading sounds');
    if (_hiddenBlockPlay()) {
      return;
    }
    await soLoudEnsureInitialised();
    await Future.wait(<Future<AudioSource>>[
      for (SfxType type in SfxType.values)
        if (type != SfxType.silence)
          //load everything up, but silence doesn't go through soLoud
          _getSoLoudSound(type, preload: true),
    ]);
  }

  /// Disposes of all audio resources and shut downs the controllers.
  Future<void> dispose() async {
    //don't call manually
    _log.info("Dispose - don't call manually");
    //_lifecycleNotifier?.removeListener(_handleAppLifecycle);
    await _soLoudPowerDownForReset();
    assert(_soLoudSources.isEmpty);
    assert(_soLoudHandles.isEmpty);
  }

  /// Disposes of all active SoLoud audio sources.
  Future<void> _soLoudDisposeAllSources() async {
    _log.fine("soLoudDisposeAllSources and clear");
    _clearSources();
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

  /// Shuts down the SoLoud engine without clearing internal source caches.
  void _soLoudDeInitOnly() {
    //don't call directly
    _log.fine("soLoudDeInitOnly");
    assert(_soLoudSources.isEmpty);
    assert(_soLoudHandles.isEmpty);
    soLoud.deinit();
  }

  /// Clears the cached SoLoud audio sources.
  void _clearSources() {
    _log.fine("clearSources");
    _clearHandles();
    _soLoudSources.clear();
    assert(_soLoudSources.isEmpty);
    assert(_soLoudHandles.isEmpty);
  }

  /// Clears the cached SoLoud sound handles.
  void _clearHandles() {
    _log.fine("clearHandles");
    _soLoudHandles.clear();
    //assert(_soLoudSources.isEmpty);
    assert(_soLoudHandles.isEmpty);
  }

  /// Shuts down the SoLoud engine completely to prepare for a reset.
  Future<void> _soLoudPowerDownForReset() async {
    if (!isAudioSystemEnabled) {
      return;
    }
    assert(soLoudIsUnreliable);
    _log.fine("soLoudPowerDownForReset");
    await stopAllSounds(); //FIXME is this necessary with disposeAllSources next line
    await _soLoudDisposeAllSources(); //FIXME is this necessary with deinit next line (if switch to just deinit, must clear sources separately)
    //clearSources();
    assert(_soLoudSources.isEmpty);
    assert(_soLoudHandles.isEmpty);
    _soLoudDeInitOnly();
    _log.fine("soLoudReset complete");
  }
}
