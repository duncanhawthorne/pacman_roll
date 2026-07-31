import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:logging/logging.dart';

import '../app_lifecycle/app_lifecycle.dart';
import '../settings/settings.dart';
import 'ios_audio.dart';
import 'siren_audio.dart';
import 'sounds.dart';

/// Global flag enabling or disabling the audio engine system.
const bool kEnableAudioSystem = true;

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

  /// Instance of the SoLoud C++/Wasm audio engine.
  final SoLoud _soLoud = SoLoud.instance;

  /// Sub-controller responsible for dynamic ghost siren sound modulation.
  late final SirenAudioController siren = SirenAudioController(this, _soLoud);

  /// Sub-controller responsible for managing iOS WebAudio unlock requirements.
  late final IosWorkaround iosWorkaround = IosWorkaround(this);

  static final Logger _log = Logger('AC');
  static final Logger _logLC = Logger('LC');

  SettingsController? _settings;
  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  /// Caches for SoLoud audio sources and active voice handles.
  final Map<SfxType, Future<AudioSource>> _sources =
      <SfxType, Future<AudioSource>>{};
  final Map<SfxType, SoundHandle> _handles = <SfxType, SoundHandle>{};

  /// Holds singleton instance reference.
  static AudioController? _instance;

  /// Retrieves the active [SoundHandle] for the specified [SfxType] if retained.
  SoundHandle? getHandle(SfxType type) => _handles[type];

  /// Checks if audio is enabled in system constants and user settings.
  bool get _isAudioOn =>
      kEnableAudioSystem && (_settings?.audioOn.value ?? true);

  /// Evaluates whether the engine is allowed to initialize or resume audio playback.
  ///
  /// Returns `false` if audio settings are disabled, if the audio stack is locked on iOS,
  /// or if the app lifecycle state is [AppLifecycleState.hidden].
  bool get _canInitialize =>
      _isAudioOn &&
      _isAudioStackUnlocked &&
      _lifecycleNotifier?.value != AppLifecycleState.hidden;

  /// IOS SAFARI GUARD:
  /// Delegates directly to [iosWorkaround.isReady]. On non-iOS platforms, this returns true immediately.
  bool get _isAudioStackUnlocked => iosWorkaround.isReady;

  /// Validates whether a sound can safely be played.
  ///
  /// IOS GUARD: Rejects playback if the app is hidden or if iOS WebAudio is locked waiting for a tap.
  /// If uninitialized, lazily attempts to initialize SoLoud and returns `false` during the spin-up frame.
  bool canPlay(SfxType type) {
    if (!isInitializedOrInitializeAsync()) return false;

    if (type != SfxType.ghostsRoamingSiren) {
      _log.finest('Can play: $type');
    }
    return true;
  }

  /// Synchronously checks if a specific sound type is currently playing and unpaused.
  bool isPlaying(SfxType type) {
    if (!_handleValidToPlay(type)) return false;
    final SoundHandle? handle = getHandle(type);
    final bool isPaused = handle != null && _soLoud.getPause(handle);
    return !isPaused;
  }

  /// Plays a specific sound effect using SoLoud.
  ///
  /// Prunes stale handles prior to playback. If the sound is marked as [SfxType.longSound],
  /// any existing playback handle for that sound type is stopped before playing anew.
  Future<void> play(SfxType type) async {
    if (!canPlay(type)) return;
    assert(type.toPlayInSoLoud);
    _pruneStaleHandles();

    try {
      final AudioSource sound = await _getSoundSource(type);
      if (!canPlay(type)) return; // in case state changed via await above
      final bool retainForStopping = type.longSound;

      if (retainForStopping && _handleValidToPlay(type)) {
        _log.info("Retained handle, stopping to replay");
        unawaited(_soLoud.stop(_handles[type]!));
      }

      final SoundHandle fHandle = _soLoud.play(
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

  /// Stops a specific playing sound effect asynchronously.
  ///
  /// Handles cleanup safely even if the engine is uninitialized or handle is defunct.
  Future<void> stopSound(SfxType type, [bool fromStopAll = false]) async {
    if (!kEnableAudioSystem) return;

    assert(type.toPlayInSoLoud);
    if (!fromStopAll) _log.fine("stopSfx $type");

    // If uninitialized, stale handles are already defunct in C++/Wasm, so just remove them
    if (!_soLoud.isInitialized) {
      _handles.remove(type);
      return;
    }

    final SoundHandle? fHandle = _handles.remove(type);
    if (fHandle != null && _soLoud.getIsValidVoiceHandle(fHandle)) {
      await _soLoud.stop(fHandle);
    }
  }

  /// Stops all tracked playing sounds safely.
  Future<void> stopAllSounds() async {
    if (!kEnableAudioSystem) return;
    _log.fine('Stop all sounds ${_handles.keys}');
    await Future.wait(
      _handles.keys.toList().map((SfxType type) => stopSound(type, true)),
    );
  }

  Future<void> _initialize() async {
    _log.info("soLoud not initialized, re-initialize");
    _clearSources();
    await _soLoud.init();
    _soLoud.setMaxActiveVoiceCount(64);
    assert(_soLoud.isInitialized);
    _log.info("soLoud now initialized");
    unawaited(_preloadSounds());
  }

  /// Ensures that the SoLoud engine is initialized and ready for use.
  ///
  /// IOS GUARD: Blocked if iOS audio is currently locked (waiting for user touch).
  /// Returns `true` if SoLoud is initialized, or `false` if initialization was newly kicked off or blocked.
  bool isInitializedOrInitializeAsync() {
    if (!_canInitialize) return false;

    if (!_soLoud.isInitialized) {
      _initialize();
      return false;
    }
    return true;
  }

  /// Preloads sound effects into memory.
  Future<void> _preloadSounds() async {
    _log.fine('Preloading sounds');
    assert(_soLoud.isInitialized);
    if (!_soLoud.isInitialized) return;
    await Future.wait(
      SfxType.values
          .where((SfxType type) => type.toPlayInSoLoud)
          .map((SfxType type) => _getSoundSource(type, preload: true)),
    );
  }

  /// Loads or retrieves a cached SoLoud audio source.
  ///
  /// Validates cached sources against [_soLoud.activeSounds] before returning.
  Future<AudioSource> _getSoundSource(
    SfxType type, {
    bool preload = false,
  }) async {
    assert(_canInitialize);
    if (!_soLoud.isInitialized) {
      await _initialize();
    }
    assert(type.toPlayInSoLoud);

    final Future<AudioSource>? existingFuture = _sources[type];
    if (existingFuture != null) {
      final AudioSource source = await existingFuture;
      if (_soLoud.activeSounds.contains(source)) {
        return source;
      }
    }

    if (!preload) _log.fine("New audio source $type");

    return _sources[type] = _soLoud.loadAsset(
      'assets/${type.filename}',
      mode: LoadMode.memory,
    );
  }

  /// Prunes invalid or finished voice handles from memory to prevent reaching max active voice limits.
  void _pruneStaleHandles() {
    if (!_soLoud.isInitialized) return;
    _handles.removeWhere(
      (SfxType type, SoundHandle handle) =>
          !_soLoud.getIsValidVoiceHandle(handle),
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
    if (!_canInitialize || !_soLoud.isInitialized) return false;
    final SoundHandle? handle = _handles[type];
    return handle != null && _soLoud.getIsValidVoiceHandle(handle);
  }

  /// Binds the lifecycle notifier and settings controller dependencies to this controller.
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

  /// Clears cached SoLoud audio sources and tracked handles.
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
    if (_soLoud.isInitialized) {
      await _soLoud.disposeAllSources().catchError(
        (Object e) => _log.severe("Crash on disposeAllSources $e"),
      );
    }
    _soLoud.deinit();
    _log.info("soLoudPowerDownForReset complete");
  }
}
