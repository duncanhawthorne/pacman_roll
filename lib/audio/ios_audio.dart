import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:logging/logging.dart';

import '../utils/constants.dart';
import 'audio_controller.dart';
import 'sounds.dart';

/// Manages the HTML5 Audio stream workaround required to keep WebAudio
/// unlocked and active on iOS Safari / iOS Chrome.
class IosWorkaround {
  IosWorkaround({required this.isAudioOn});

  /// Callback to verify if system & user audio settings are enabled.
  final bool Function() isAudioOn;

  static final Logger _log = Logger('IA');

  AudioPlayer? _silencePlayer;

  /// Platform check: true only if running on iOS Safari / iOS Web.
  final bool _soLoudIsUnreliable = isiOSWeb;

  /// DEBOUNCE GUARD: Prevents fast back-to-back user taps from firing multiple async `.play()`
  /// calls on HTML5 Audio, which causes iOS Safari to throw "AbortError: The operation was aborted".
  bool _needsReUnlockOnResume = true;
  bool _isUnlockingSilence = false;

  /// Returns true if iOS WebAudio has been unlocked by a user gesture.
  bool get _isUnlocked => !_needsReUnlockOnResume;

  /// CLEAN GUARD CHECK:
  /// Returns true immediately on non-iOS platforms, or if iOS WebAudio is unlocked.
  bool get isReady => !_soLoudIsUnreliable || _isUnlocked;

  /// Checks if playing silent audio via HTML5 Audio is applicable for this environment.
  bool get _silenceGenerallyPlayable =>
      kEnableAudioSystem && _soLoudIsUnreliable;

  bool get _silencePlayableNow => _silenceGenerallyPlayable && isAudioOn.call();

  /// Determines whether hiding the app should trigger a full engine teardown.
  bool get onHideDoFullShutdown => _silenceGenerallyPlayable;

  /// Safari workaround: Triggers audio activation on a user-initiated touch event (PointerDown).
  Future<void> workaround() async {
    // GUARD: If already unlocked OR an unlock attempt is currently in progress, do nothing.
    if (!_silencePlayableNow || _isUnlocked || _isUnlockingSilence) return;

    _log.info('User interacted with screen. workaround() called.');
    _isUnlockingSilence = true;

    try {
      await _playSilence();
    } finally {
      _isUnlockingSilence = false;
    }
  }

  /// Plays a silent track via HTML5 Audio to keep the browser audio session active.
  ///
  /// Performs back-to-back `.play()` calls to guarantee Safari binds the hardware audio node cleanly.
  Future<void> _playSilence() async {
    if (!_silencePlayableNow) return;

    if (_silencePlayer?.state == PlayerState.playing) {
      _needsReUnlockOnResume = false;
      _log.fine('Silence already playing');
      return;
    }

    _log.fine('playSilence');
    final SfxType type = SfxType.silence;

    if (_silencePlayer != null) {
      await _silencePlayer?.stop().catchError((_) {});
    } else {
      _silencePlayer = AudioPlayer(playerId: 'sfxPlayer#$type');
    }

    if (!_silencePlayableNow) return;

    final AudioPlayer currentPlayer = _silencePlayer!;
    await currentPlayer.setReleaseMode(ReleaseMode.loop);

    try {
      // Double call ensures Safari gesture stack binds the hardware audio node cleanly.
      await currentPlayer
          .play(AssetSource(type.filename), volume: type.targetVolume)
          .timeout(const Duration(seconds: 2));

      if (!_silencePlayableNow || _silencePlayer == null) {
        await currentPlayer.stop().catchError((_) {});
        return;
      }

      await currentPlayer
          .play(AssetSource(type.filename), volume: type.targetVolume)
          .timeout(const Duration(seconds: 2));

      _needsReUnlockOnResume = false;
      _log.info('Silence stream restarted. WebAudio hardware is UNLOCKED.');
    } catch (e) {
      _log.warning('Silence playback warning/error: $e');

      /// Ensure partial audio player instance is disposed if play() fails/times out
      unawaited(releaseWorkaround());
    }

    _log.finest(() => 'Player state $type ${currentPlayer.state}');
  }

  /// Stops silence and clears player instance.
  Future<void> releaseWorkaround() async {
    if (!_silenceGenerallyPlayable) return;

    _needsReUnlockOnResume = true;
    _log.fine('Stop silence as part of all ${_silencePlayer?.state}');
    final AudioPlayer? player = _silencePlayer;
    _silencePlayer = null;
    _isUnlockingSilence = false;

    if (player != null) {
      await player.stop().catchError((_) {});
      await player.dispose().catchError((_) {});
    }
  }

  /// Called on AppLifecycleState.resumed to invalidate silence player state
  /// and flag the stack as requiring a re-unlock gesture.
  void handleLifecycleResume() {
    if (!_silenceGenerallyPlayable) return;
    _log.info('Flagging IosWorkaround for re-unlock on next user tap.');
    _needsReUnlockOnResume = true;
    _isUnlockingSilence = false;
  }
}
