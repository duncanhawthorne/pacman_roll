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

/// Performs the initial setup of the SoLoud audio engine on app launch.
Future<void> firstInitializeSoLoud() async {
  if (!kEnableAudioSystem) return;
  await _initEngine().catchError((Object e) => logGlobal("SoLoud crash $e"));
}

Future<void> _initEngine() async {
  await soLoud.init();
  soLoud.setMaxActiveVoiceCount(64);
}

/// Global instance of the SoLoud C++/Wasm audio engine.
final SoLoud soLoud = SoLoud.instance;

/// Global audio controller that manages sound effects, music, and iOS Web lifecycle recovery.
class AudioController {
  AudioController._() {
    isInitializedOrInitializeAsync();
  }

  /// Returns the singleton instance of the [AudioController].
  ///
  /// DEBUG PATTERN: The assertion [_instance == null] is an intentional guardrail.
  /// It ensures this factory is only ever called exactly once (e.g., during root
  /// dependency injection). If called a second time in debug mode, it crashes to
  /// flag the architectural mistake. In production, assertions are stripped,
  /// so it safely falls back to returning the existing instance without crashing.
  factory AudioController() {
    assert(_instance == null);
    _instance ??= AudioController._();
    return _instance!;
  }

  late final SirenAudioController siren = SirenAudioController(this);
  late final IosWorkaround iosWorkaround = IosWorkaround(this);

  static final Logger _log = Logger('AC');
  static final Logger _logLC = Logger('LC');

  SettingsController? _settings;
  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  /// Caches for SoLoud audio sources and handles.
  final Map<SfxType, Future<AudioSource>> _sources =
      <SfxType, Future<AudioSource>>{};
  final Map<SfxType, SoundHandle> _handles = <SfxType, SoundHandle>{};

  /// Holds singleton instance reference.
  static AudioController? _instance;

  SoundHandle? getHandle(SfxType type) => _handles[type];

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

  /// Validates whether a sound can safely be played.
  /// IOS GUARD: Rejects playback if the app is hidden or if iOS WebAudio is locked waiting for a tap.
  /// If uninitialized, lazily attempts to initialize SoLoud.
  Future<bool> canPlay(SfxType type) async {
    if (!_canInitialize) return false;
    if (!isInitializedOrInitializeAsync()) return false;

    if (type != SfxType.ghostsRoamingSiren) {
      _log.finest('Can play: $type');
    }
    return true;
  }

  /// Synchronously checks if a sound is currently playing.
  bool isPlaying(SfxType type) {
    if (!_handleValidToPlay(type)) return false;
    final SoundHandle? handle = getHandle(type);
    final bool isPaused = handle != null && soLoud.getPause(handle);
    return !isPaused;
  }

  /// Plays a specific sound effect using SoLoud.
  Future<void> play(SfxType type) async {
    if (!(await canPlay(type))) return;
    assert(type.toPlayInSoLoud);
    _pruneStaleHandles();

    try {
      final AudioSource sound = await _getSoundSource(type);
      final bool retainForStopping = type.longSound;

      if (retainForStopping && _handleValidToPlay(type)) {
        _log.info("Retained handle, stopping to replay");
        unawaited(soLoud.stop(_handles[type]!));
      }

      final SoundHandle fHandle = soLoud.play(
        sound,
        paused: false,
        looping: type.looping,
        volume: type.targetVolume,
      );

      if (retainForStopping) {
        _handles[type] = fHandle;
      }
    } catch (e) {
      _log.severe('SoLoud play crash $type $e');
      await _powerDownForReset();
    }
  }

  /// Stops a specific playing sound effect.
  /// Safe to call synchronously when engine is deinitialized.
  Future<void> stopSound(SfxType type, [bool fromStopAll = false]) async {
    if (!kEnableAudioSystem) return;

    assert(type.toPlayInSoLoud);
    if (!fromStopAll) _log.fine("stopSfx $type");

    // If uninitialized, stale handles are already defunct in C++/Wasm, so just remove them
    if (!soLoud.isInitialized) {
      _handles.remove(type);
      return;
    }

    final SoundHandle? fHandle = _handles.remove(type);
    if (fHandle != null && soLoud.getIsValidVoiceHandle(fHandle)) {
      await soLoud.stop(fHandle);
    }
  }

  /// Stops all playing sounds safely.
  Future<void> stopAllSounds() async {
    if (!kEnableAudioSystem) return;
    _log.fine('Stop all sounds ${_handles.keys}');
    await Future.wait(<Future<void>>[
      for (final SfxType type in _handles.keys.toList()) stopSound(type, true),
    ]);
  }

  Future<void> _initialize() async {
    _log.info("soLoud not initialized, re-initialize");
    _clearSources();
    await _initEngine();
    assert(soLoud.isInitialized);
    _log.info("soLoud now initialized");
    unawaited(_preloadSounds());
  }

  /// Ensures that the SoLoud engine is initialized and ready for use.
  /// IOS GUARD: Blocked if iOS audio is currently locked (waiting for user touch).
  /// Bypasses initialization if already initialized or stack is locked.
  bool isInitializedOrInitializeAsync() {
    if (!_canInitialize) return false;

    if (!soLoud.isInitialized) {
      _initialize();
      return false;
    }
    return true;
  }

  /// Preloads sound effects into memory.
  Future<void> _preloadSounds() async {
    _log.fine('Preloading sounds');
    assert(soLoud.isInitialized);
    if (!soLoud.isInitialized) return;
    await Future.wait(<Future<AudioSource>>[
      for (SfxType type in SfxType.values)
        if (type.toPlayInSoLoud) _getSoundSource(type, preload: true),
    ]);
  }

  /// Loads or retrieves a cached SoLoud audio source.
  Future<AudioSource> _getSoundSource(
    SfxType type, {
    bool preload = false,
  }) async {
    assert(_canInitialize);
    if (!soLoud.isInitialized) {
      await _initialize();
    }
    assert(type.toPlayInSoLoud);

    if (isAudioStackUnlocked && soLoud.isInitialized) {
      final Future<AudioSource>? existingFuture = _sources[type];
      if (existingFuture != null) {
        final AudioSource source = await existingFuture;
        if (soLoud.activeSounds.contains(source)) {
          return source;
        }
      }
    }

    if (!preload) _log.fine("New audio source $type");

    return _sources[type] = soLoud.loadAsset(
      'assets/${type.filename}',
      mode: LoadMode.memory,
    );
  }

  /// Prunes invalid or finished voice handles from memory to prevent reaching max active voice limits.
  void _pruneStaleHandles() {
    if (!soLoud.isInitialized) return;
    _handles.removeWhere(
      (SfxType type, SoundHandle handle) =>
          !soLoud.getIsValidVoiceHandle(handle),
    );
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
        if (iosWorkaround.onHideDoFullShutdown) {
          await _powerDownForReset();
        } else {
          await stopAllSounds();
        }
      case AppLifecycleState.resumed:
        iosWorkaround.handleLifecycleResume();
      default:
        break;
    }
  }

  /// Synchronously checks if a voice handle is valid.
  /// If the engine is uninitialized or audio stack is locked, returns `false` instantly without awaiting.
  bool _handleValidToPlay(SfxType type) {
    if (!_canInitialize || !soLoud.isInitialized) return false;
    final SoundHandle? handle = _handles[type];
    return handle != null && soLoud.getIsValidVoiceHandle(handle);
  }

  void attachDependencies(
    AppLifecycleStateNotifier lifecycleNotifier,
    SettingsController settingsController,
  ) {
    // Attach lifecycle listener
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
    _lifecycleNotifier = lifecycleNotifier..addListener(_handleAppLifecycle);

    // Attach settings listener
    if (_settings != settingsController) {
      _settings?.audioOn.removeListener(_audioOnOffHandler);
      _settings = settingsController..audioOn.addListener(_audioOnOffHandler);
    }
  }

  void _audioOnOffHandler() {
    _log.fine('audioOn changed to ${_settings!.audioOn.value}');
    if (_settings!.audioOn.value) {
      iosWorkaround.workaround();
    } else {
      stopAllSounds();
      iosWorkaround.releaseWorkaround();
    }
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
    _handles.clear();
    _sources.clear();
  }

  /// Fully shuts down SoLoud when backgrounding or resetting engine state on iOS.
  Future<void> _powerDownForReset() async {
    if (!kEnableAudioSystem) return;
    _log.fine("soLoudPowerDownForReset start");
    await stopAllSounds();
    unawaited(iosWorkaround.releaseWorkaround());
    _clearSources();
    if (soLoud.isInitialized) {
      await soLoud.disposeAllSources().catchError(
        (Object e) => _log.severe("Crash on disposeAllSources $e"),
      );
    }
    soLoud.deinit();
    _log.info("soLoudPowerDownForReset complete");
  }
}
