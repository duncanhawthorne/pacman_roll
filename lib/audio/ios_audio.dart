import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:logging/logging.dart';

import '../utils/constants.dart';
import 'audio_controller.dart';
import 'sounds.dart';

/// Manages the HTML5 Audio stream workaround required to keep WebAudio
/// unlocked and active on iOS Safari / iOS Chrome.
class IosWorkaround {
  IosWorkaround(this._audioController);

  static final Logger _log = Logger('IA');
  final AudioController _audioController;

  AudioPlayer? _silencePlayer;

  /// Platform check: true only if running on iOS Safari / iOS Web.
  final bool _soLoudIsUnreliable = isiOSWeb;

  bool _needsReUnlockOnResume = false;

  /// DEBOUNCE GUARD: Prevents fast back-to-back user taps from firing multiple async `.play()`
  /// calls on HTML5 Audio, which causes iOS Safari to throw "AbortError: The operation was aborted".
  bool _isUnlockingSilence = false;

  /// Returns true if iOS WebAudio has been unlocked by a user gesture.
  bool get _isUnlocked => !_needsReUnlockOnResume;

  /// CLEAN GUARD CHECK:
  /// Returns true immediately on non-iOS platforms, or if iOS WebAudio is unlocked.
  bool get isReady => !_soLoudIsUnreliable || _isUnlocked;

  bool get _silencePlayable => kEnableAudioSystem && _soLoudIsUnreliable;

  /// Handles AppLifecycleState.hidden teardown for unreliable platform audio.
  Future<void> handleLifecycleHidden(
    Future<void> Function() powerDownResetCallback,
  ) async {
    if (_silencePlayable) {
      _log.info("soLoudReset due to unreliable soLoud");
      await powerDownResetCallback();
    } else {
      await _audioController.stopAllSounds();
    }
  }

  /// Called on AppLifecycleState.resumed to invalidate the silence player state.
  void resetStateOnResume() {
    if (!_silencePlayable) return;
    _log.info('Flagging IosWorkaround for re-unlock on next user tap.');
    _needsReUnlockOnResume = true;
    _isUnlockingSilence = false;
  }

  /// Safari workaround: Triggers audio activation on a user-initiated touch event (PointerDown).
  /// Synchronously clears _needsReUnlockOnResume and forces SoLoud re-init inside the gesture callstack.
  Future<void> workaround() async {
    // GUARD: If already unlocked OR an unlock attempt is currently in progress, do nothing.
    if (_isUnlocked || _isUnlockingSilence) return;

    _log.info('User interacted with screen. workaround() called.');
    _isUnlockingSilence = true;

    // UNLOCK IMMEDIATELY inside the user tap callstack
    _needsReUnlockOnResume = false;

    // Force SoLoud re-initialization synchronously inside the user tap gesture stack
    _audioController.soLoudIsInitializedOrInitializeAsync();

    await _playSilence();
  }

  /// Plays a silent track via HTML5 Audio to keep the browser audio session active.
  Future<void> _playSilence() async {
    if (!_silencePlayable) return;

    if (_silencePlayer?.state == PlayerState.playing) {
      _log.fine('Silence already playing');
      _isUnlockingSilence = false;
      return;
    }
    _log.fine("playSilence");
    final SfxType type = SfxType.silence;

    if (_silencePlayer != null) {
      await _silencePlayer?.stop().catchError((_) {});
    } else {
      _silencePlayer = AudioPlayer(playerId: 'sfxPlayer#$type');
    }

    final AudioPlayer currentPlayer = _silencePlayer!;
    await currentPlayer.setReleaseMode(ReleaseMode.loop);

    try {
      // Double call ensures Safari gesture stack binds the hardware audio node cleanly.
      await currentPlayer.play(
        AssetSource(type.filename),
        volume: type.targetVolume,
      );
      await currentPlayer.play(
        AssetSource(type.filename),
        volume: type.targetVolume,
      );

      _log.info('Silence stream restarted. WebAudio hardware is UNLOCKED.');
    } catch (e) {
      _log.warning('Silence playback warning/error: $e');
    } finally {
      _isUnlockingSilence = false;
    }

    _log.finest(() => "Player state $type ${currentPlayer.state}");
  }

  /// Stops all currently playing sounds and clears players map.
  Future<void> stopAllSounds() async {
    if (!_silencePlayable) return;
    if (_silencePlayer != null) {
      await _silencePlayer!.stop().catchError((_) {});
      _log.fine('Stop silence as part of all ${_silencePlayer?.state}');
    }
    _silencePlayer = null;
    _isUnlockingSilence = false;
  }
}
