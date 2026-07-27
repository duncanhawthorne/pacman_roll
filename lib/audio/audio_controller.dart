import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:logging/logging.dart';

import '../app_lifecycle/app_lifecycle.dart';
import '../settings/settings.dart';
import '../utils/helper.dart';
import 'ios_audio.dart';
import 'siren_audio.dart';
import 'sounds.dart';

const bool kEnableAudioSystem = true;

final bool detailedAudioLog = true;

/// Performs the initial setup of the SoLoud audio engine on app launch.
Future<void> firstInitialiseSoLoud() async {
  if (!kEnableAudioSystem) return;
  try {
    await soLoud.init();
    soLoud.setMaxActiveVoiceCount(64);
  } catch (e) {
    logGlobal("SoLoud crash");
  }
}

/// Global instance of the SoLoud C++/Wasm audio engine.
final SoLoud soLoud = SoLoud.instance;

/// Global audio controller that manages sound effects, music, and iOS Web lifecycle recovery.
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

  /// Holds singleton instance reference.
  static AudioController? _instance;

  SoundHandle? getHandle(SfxType type) => _soLoudHandles[type];

  /// Checks if audio is enabled in settings and not muted.
  bool get isAudioOn =>
      kEnableAudioSystem && (_settings?.audioOn.value ?? true);

  /// IOS SAFARI GUARD:
  /// Delegates directly to [iosWorkaround.isReady]. On non-iOS platforms, this returns true immediately.
  bool get isAudioStackUnlocked => iosWorkaround.isReady;

  static final Logger _log = Logger('AC');
  static final Logger _logLC = Logger('LC');

  SettingsController? _settings;
  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  /// Caches for SoLoud audio sources and handles.
  final Map<SfxType, Future<AudioSource>> _soLoudSources =
      <SfxType, Future<AudioSource>>{};
  final Map<SfxType, SoundHandle> _soLoudHandles = <SfxType, SoundHandle>{};

  /// Prunes invalid or finished voice handles from memory to prevent reaching max active voice limits.
  void _pruneStaleHandles() {
    if (!soLoud.isInitialized) return;
    _soLoudHandles.removeWhere(
      (SfxType type, SoundHandle handle) =>
          !soLoud.getIsValidVoiceHandle(handle),
    );
  }

  /// Loads or retrieves a cached SoLoud audio source.
  Future<AudioSource> _getSoLoudSound(
    SfxType type, {
    bool preload = false,
  }) async {
    await soLoudEnsureInitialised();
    assert(type != SfxType.silence);

    if (isAudioStackUnlocked) {
      final Future<AudioSource>? existingFuture = _soLoudSources[type];
      if (existingFuture != null) {
        final AudioSource source = await existingFuture;
        if (soLoud.activeSounds.contains(source)) {
          return source;
        }
      }
    }

    unawaited(_soLoudSources.remove(type));
    if (!preload) _log.fine("New audio source $type");

    final Future<AudioSource> currentSound = soLoud.loadAsset(
      'assets/${type.filename}',
      mode: LoadMode.memory,
    );
    _soLoudSources[type] = currentSound;
    return currentSound;
  }

  /// Validates whether a sound can safely be played.
  /// IOS GUARD: Rejects playback if the app is hidden or if iOS WebAudio is locked waiting for a tap.
  Future<bool> canPlay(SfxType type) async {
    if (!kEnableAudioSystem) return false;

    if (_hiddenBlockPlay()) {
      _log.info("App hidden can't play $type");
      return false;
    }

    // IOS SAFARI GUARD: Block playing or re-initializing until user physically touches screen.
    if (!isAudioStackUnlocked) {
      if (type != SfxType.ghostsRoamingSiren) {
        _log.info(
          "[GUARD] canPlay($type) BLOCKED: Waiting for user touch to unlock iOS audio.",
        );
      }
      return false;
    }

    await soLoudEnsureInitialised();
    if (!soLoud.isInitialized) {
      _log.severe("canPlay SoLoud not initialised, after ensureInitialised");
      return false;
    }

    final bool audioOn = isAudioOn;
    if (!audioOn) {
      return false;
    }

    if (type != SfxType.ghostsRoamingSiren) {
      _log.finest('Can play: $type');
    }
    return true;
  }

  Future<bool> isPlaying(SfxType type) async {
    if (!await _soLoudHandleValid(type)) return false;
    final SoundHandle? handle = getHandle(type);
    final bool isPaused = handle != null && soLoud.getPause(handle);
    return !isPaused;
  }

  /// Plays a specific sound effect using SoLoud.
  Future<void> play(SfxType type) async {
    if (!kEnableAudioSystem) return;
    if (isAudioOn) _log.finest('Playing $type');
    if (!(await canPlay(type))) return;

    _pruneStaleHandles();

    final bool looping =
        type == SfxType.ghostsRoamingSiren || type == SfxType.ghostsScared;
    try {
      await soLoudEnsureInitialised();
      final AudioSource sound = await _getSoLoudSound(type);
      final bool retainForStopping =
          looping || type == SfxType.startMusic || type == SfxType.endMusic;
      if (retainForStopping) {
        if (await _soLoudHandleValid(type)) {
          _log.info(() => "Retained handle, stopping to replay");
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
    } catch (e) {
      _log
        ..severe('SoLoud play crash, reset $type')
        ..severe(e);
      await _soLoudPowerDownForReset();
    }
  }

  /// Returns true if the app is hidden in background.
  bool _hiddenBlockPlay() {
    return _lifecycleNotifier == null ||
        _lifecycleNotifier!.value == AppLifecycleState.hidden;
  }

  /// Stops a specific playing sound effect.
  Future<void> stopSound(SfxType type) async {
    if (!kEnableAudioSystem) return;

    assert(type != SfxType.silence);
    if (isAudioOn) _log.fine("stopSfx $type");

    // IOS GUARD: Prevent triggering ensureInitialised if iOS isn't unlocked
    if (!isAudioStackUnlocked) return;

    await soLoudEnsureInitialised();
    if (await _soLoudHandleValid(type)) {
      final SoundHandle fHandle = _soLoudHandles[type]!;
      _soLoudHandles.remove(type);
      await soLoud.stop(fHandle);
    }
  }

  /// Stops all playing sounds safely using a list snapshot to prevent concurrent modification errors.
  Future<void> stopAllSounds() async {
    if (!kEnableAudioSystem) return;
    _log.fine(() => <Object>['Stop all sound', _soLoudHandles.keys]);

    for (final SfxType type in _soLoudHandles.keys.toList()) {
      await stopSound(type);
    }
    _soLoudHandles.clear();

    await iosWorkaround.stopAllSounds();
  }

  Future<bool> _soLoudHandleValid(SfxType type) async {
    if (!isAudioStackUnlocked) return false;
    await soLoudEnsureInitialised();
    final SoundHandle? handle = _soLoudHandles[type];
    return handle != null && soLoud.getIsValidVoiceHandle(handle);
  }

  void attachDependencies(
    AppLifecycleStateNotifier lifecycleNotifier,
    SettingsController settingsController,
  ) {
    _attachLifecycleNotifier(lifecycleNotifier);
    _attachSettings(settingsController);
  }

  void _attachLifecycleNotifier(AppLifecycleStateNotifier lifecycleNotifier) {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
    lifecycleNotifier.addListener(_handleAppLifecycle);
    _lifecycleNotifier = lifecycleNotifier;
  }

  void _attachSettings(SettingsController settingsController) {
    if (_settings == settingsController) return;

    final SettingsController? oldSettings = _settings;
    if (oldSettings != null) {
      oldSettings.audioOn.removeListener(_audioOnOffHandler);
    }

    _settings = settingsController;
    settingsController.audioOn.addListener(_audioOnOffHandler);
  }

  void _audioOnOffHandler() {
    _log.fine('audioOn changed to ${_settings!.audioOn.value}');
    if (_settings!.audioOn.value) {
      iosWorkaround.workaround();
    } else {
      stopAllSounds();
    }
  }

  /// IOS LIFECYCLE MANAGEMENT:
  /// Delegates lifecycle handling to [IosWorkaround].
  Future<void> _handleAppLifecycle() async {
    if (!kEnableAudioSystem) return;
    switch (_lifecycleNotifier!.value) {
      case AppLifecycleState.paused:
        _logLC.info("Lifecycle paused");
      case AppLifecycleState.detached:
        _logLC.info("Lifecycle detached");
      case AppLifecycleState.hidden:
        _logLC.info("Lifecycle hidden");
        await iosWorkaround.handleLifecycleHidden(_soLoudPowerDownForReset);
      case AppLifecycleState.resumed:
        _logLC.info("Lifecycle resumed");
        iosWorkaround.resetStateOnResume();
      case AppLifecycleState.inactive:
        _logLC.info("Lifecycle inactive");
        break;
    }
  }

  /// Ensures that the SoLoud engine is initialized and ready for use.
  /// IOS GUARD: Blocked if iOS audio is currently locked (waiting for user touch).
  Future<void> soLoudEnsureInitialised() async {
    if (!kEnableAudioSystem) return;

    // IOS SAFARI GUARD: Do NOT re-init SoLoud programmatically on lifecycle resume!
    // Wait until the user physically touches the screen (isIosUnlocked == true)
    if (!isAudioStackUnlocked) {
      _log.finest(
        "[GUARD] soLoudEnsureInitialised BLOCKED: Waiting for user touch.",
      );
      return;
    }

    if (!soLoud.isInitialized) {
      _log.info("soLoud not initialised, re-initialise");
      assert(!_hiddenBlockPlay());
      _clearSources();
      await soLoud.init();
      soLoud.setMaxActiveVoiceCount(64);
      assert(soLoud.isInitialized);
      _log.info("soLoud now initialised");
      unawaited(_preloadSfx());
    }
  }

  /// Preloads sound effects into memory.
  Future<void> _preloadSfx() async {
    _log.fine('Preloading sounds');
    if (_hiddenBlockPlay() || !isAudioStackUnlocked) return;
    await soLoudEnsureInitialised();
    await Future.wait(<Future<AudioSource>>[
      for (SfxType type in SfxType.values)
        if (type != SfxType.silence) _getSoLoudSound(type, preload: true),
    ]);
  }

  /// SINGLETON PROTECTION:
  /// Overridden to prevent Provider widget disposal from destroying the global singleton instance.
  Future<void> dispose() async {
    _log.info("Dispose request from Provider - ignoring to preserve singleton");
    // Do NOT destroy singleton on Provider disposal
  }

  /// Disposes of all active SoLoud audio sources.
  Future<void> _soLoudDisposeAllSources() async {
    _log.fine("soLoudDisposeAllSources and clear");
    _clearSources();
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

  /// Shuts down the SoLoud C++ engine.
  void _soLoudDeInitOnly() {
    _log.fine("soLoudDeInitOnly");
    assert(_soLoudSources.isEmpty);
    assert(_soLoudHandles.isEmpty);
    soLoud.deinit();
  }

  /// Clears the cached SoLoud audio sources.
  void _clearSources() {
    _log.fine("clearSources");
    _soLoudHandles.clear();
    _soLoudSources.clear();
    assert(_soLoudSources.isEmpty);
    assert(_soLoudHandles.isEmpty);
  }

  /// Fully shuts down SoLoud when backgrounding or resetting engine state on iOS.
  Future<void> _soLoudPowerDownForReset() async {
    if (!kEnableAudioSystem) return;
    _log.fine("soLoudPowerDownForReset");
    await stopAllSounds();
    await _soLoudDisposeAllSources();
    assert(_soLoudSources.isEmpty);
    assert(_soLoudHandles.isEmpty);
    _soLoudDeInitOnly();
    _log.info("soLoudReset complete");
  }
}
