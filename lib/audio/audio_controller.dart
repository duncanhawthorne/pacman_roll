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

const bool detailedAudioLog = true;

/// Performs the initial setup of the SoLoud audio engine on app launch.
Future<void> firstInitializeSoLoud() async {
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
  bool get _isAudioOn =>
      kEnableAudioSystem && (_settings?.audioOn.value ?? true);

  bool get _canInitialize =>
      _isAudioOn &&
      isAudioStackUnlocked &&
      _lifecycleNotifier?.value != AppLifecycleState.hidden;

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
    assert(_canInitialize);
    if (!soLoud.isInitialized) {
      await _initialize();
    }
    assert(type != SfxType.silence);

    if (isAudioStackUnlocked && soLoud.isInitialized) {
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
  /// If uninitialized, lazily attempts to initialize SoLoud.
  Future<bool> canPlay(SfxType type) async {
    if (!_canInitialize) return false;

    if (!soLoudIsInitializedOrInitializeAsync()) return false;

    if (type != SfxType.ghostsRoamingSiren) {
      _log.finest('Can play: $type');
    }
    return true;
  }

  /// Synchronously checks if a sound is currently playing.
  bool isPlaying(SfxType type) {
    if (!_soLoudHandleValidToPlay(type)) return false;
    final SoundHandle? handle = getHandle(type);
    final bool isPaused = handle != null && soLoud.getPause(handle);
    return !isPaused;
  }

  /// Plays a specific sound effect using SoLoud.
  Future<void> play(SfxType type) async {
    if (!(await canPlay(type))) return;

    _pruneStaleHandles();

    final bool looping =
        type == SfxType.ghostsRoamingSiren || type == SfxType.ghostsScared;
    try {
      final AudioSource sound = await _getSoLoudSound(type);
      final bool retainForStopping =
          looping || type == SfxType.startMusic || type == SfxType.endMusic;

      if (retainForStopping && _soLoudHandleValidToPlay(type)) {
        _log.info(() => "Retained handle, stopping to replay");
        unawaited(soLoud.stop(_soLoudHandles[type]!));
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

  /// Stops a specific playing sound effect.
  /// Safe to call synchronously when engine is deinitialized.
  Future<void> stopSound(SfxType type) async {
    if (!kEnableAudioSystem) return;

    assert(type != SfxType.silence);
    _log.fine("stopSfx $type");

    // If uninitialized, stale handles are already defunct in C++/Wasm
    if (!soLoud.isInitialized) {
      _soLoudHandles.remove(type);
      return;
    }

    final SoundHandle? fHandle = _soLoudHandles.remove(type);
    if (fHandle != null && soLoud.getIsValidVoiceHandle(fHandle)) {
      await soLoud.stop(fHandle);
    }
  }

  /// Stops all playing sounds safely.
  Future<void> stopAllSounds() async {
    if (!kEnableAudioSystem) return;
    _log.fine('Stop all sound ${_soLoudHandles.keys}');

    for (final SfxType type in _soLoudHandles.keys.toList()) {
      await stopSound(type);
    }

    await iosWorkaround.releaseWorkaround();
  }

  /// Synchronously checks if a voice handle is valid.
  /// If the engine is uninitialized or audio stack is locked, returns `false` instantly without awaiting.
  bool _soLoudHandleValidToPlay(SfxType type) {
    if (!_canInitialize || !soLoud.isInitialized) return false;
    final SoundHandle? handle = _soLoudHandles[type];
    return handle != null && soLoud.getIsValidVoiceHandle(handle);
  }

  void attachDependencies(
    AppLifecycleStateNotifier lifecycleNotifier,
    SettingsController settingsController,
  ) {
    // Attach lifecycle listener
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
    lifecycleNotifier.addListener(_handleAppLifecycle);
    _lifecycleNotifier = lifecycleNotifier;

    // Attach settings listener
    if (_settings != settingsController) {
      _settings?.audioOn.removeListener(_audioOnOffHandler);
      _settings = settingsController;
      _settings!.audioOn.addListener(_audioOnOffHandler);
    }
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

    final AppLifecycleState? state = _lifecycleNotifier?.value;
    if (state == null) return;
    _logLC.info('Lifecycle ${state.name}');

    switch (state) {
      case AppLifecycleState.hidden:
        await iosWorkaround.handleLifecycleHidden(_soLoudPowerDownForReset);
      case AppLifecycleState.resumed:
        iosWorkaround.handleLifecycleResume();
      default:
        break;
    }
  }

  Future<void> _initialize({bool calledFromPreload = false}) async {
    _log.info("soLoud not initialized, re-initialize");
    _clearSources();
    await soLoud.init();
    soLoud.setMaxActiveVoiceCount(64);
    assert(soLoud.isInitialized);
    _log.info("soLoud now initialized");
    if (!calledFromPreload) {
      unawaited(_preloadSfx());
    }
  }

  /// Ensures that the SoLoud engine is initialized and ready for use.
  /// IOS GUARD: Blocked if iOS audio is currently locked (waiting for user touch).
  /// Bypasses initialization if already initialized or stack is locked.
  bool soLoudIsInitializedOrInitializeAsync() {
    if (!_canInitialize) return false;

    if (!soLoud.isInitialized) {
      _initialize();
      return false;
    }
    return true;
  }

  /// Preloads sound effects into memory.
  Future<void> _preloadSfx() async {
    _log.fine('Preloading sounds');
    if (!_canInitialize) return;
    if (!soLoud.isInitialized) {
      await _initialize(calledFromPreload: true);
    }
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

  /// Clears the cached SoLoud audio sources.
  void _clearSources() {
    _log.fine("clearSources");
    _soLoudHandles.clear();
    _soLoudSources.clear();
  }

  /// Fully shuts down SoLoud when backgrounding or resetting engine state on iOS.
  Future<void> _soLoudPowerDownForReset() async {
    if (!kEnableAudioSystem) return;
    _log.fine("soLoudPowerDownForReset start");
    await stopAllSounds();
    _clearSources();
    if (soLoud.isInitialized) {
      try {
        await soLoud.disposeAllSources();
      } catch (e) {
        _log.severe("Crash on disposeAllSources $e");
      }
    }
    soLoud.deinit();
    _log.info("soLoudPowerDownForReset complete");
  }
}
