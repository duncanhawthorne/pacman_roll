import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:logging/logging.dart';

import 'audio_controller.dart';
import 'sounds.dart';

/// Manages the HTML5 Audio stream workaround required to keep WebAudio
/// unlocked and active on iOS Safari / iOS Chrome.
class IosWorkaround {
  IosWorkaround(this._audioController);

  static final Logger _log = Logger('IA');
  final AudioController _audioController;

  final Map<SfxType, AudioPlayer> _apPlayers = <SfxType, AudioPlayer>{};

  bool _needsReUnlockOnResume = false;

  /// DEBOUNCE GUARD: Prevents fast back-to-back user taps from firing multiple async `.play()`
  /// calls on HTML5 Audio, which causes iOS Safari to throw "AbortError: The operation was aborted".
  bool _isUnlockingSilence = false;

  /// Returns true if iOS WebAudio has been unlocked by a user gesture.
  bool get isUnlocked => !_needsReUnlockOnResume;

  /// Called on AppLifecycleState.resumed to invalidate the silence player state.
  void resetStateOnResume() {
    _log.info(
      '[LIFECYCLE] Flagging IosWorkaround for re-unlock on next user tap.',
    );
    _needsReUnlockOnResume = true;
    _isUnlockingSilence = false;
  }

  /// Plays a specific sound effect via AudioPlayers (HTML5 Audio).
  Future<void> _playSfxForceAudioPlayers(SfxType type) async {
    if (!isAudioSystemEnabled) {
      return;
    }
    !_audioController.isAudioOn ? null : _log.fine('Playing $type');

    if (_apPlayers.containsKey(type)) {
      try {
        await _apPlayers[type]!.stop();
      } catch (_) {}
    } else {
      _apPlayers[type] = AudioPlayer(playerId: 'sfxPlayer#$type');
    }

    final AudioPlayer currentPlayer = _apPlayers[type]!;
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

      if (type == SfxType.silence) {
        _log.info(
          '[TOUCH] Silence stream restarted successfully. WebAudio hardware is UNLOCKED.',
        );
      }
    } catch (e) {
      _log.warning('[TOUCH] Silence playback warning/error: $e');
    } finally {
      if (type == SfxType.silence) {
        _isUnlockingSilence = false;
      }
    }

    _log.finest(() => "Player state $type ${currentPlayer.state}");
  }

  /// Safari workaround: Triggers audio activation on a user-initiated touch event (PointerDown).
  /// Synchronously clears _needsReUnlockOnResume and forces SoLoud re-init inside the gesture callstack.
  Future<void> workaround() async {
    // GUARD: If already unlocked OR an unlock attempt is currently in progress, do nothing.
    if (isUnlocked || _isUnlockingSilence) {
      return;
    }

    _log.info('[TOUCH] User interacted with screen. workaround() called.');
    _isUnlockingSilence = true;

    // UNLOCK IMMEDIATELY inside the user tap callstack
    _needsReUnlockOnResume = false;

    // Force SoLoud re-initialization synchronously inside the user tap gesture stack
    unawaited(_audioController.soLoudEnsureInitialised());

    await _playSilence();
  }

  /// Returns true if silence is playing on AudioPlayers.
  bool _silencePlayingOnAp() {
    final SfxType type = SfxType.silence;
    return _apPlayers.containsKey(type) &&
        _apPlayers[type]!.state == PlayerState.playing;
  }

  /// Plays a silent track via HTML5 Audio to keep the browser audio session active.
  Future<void> _playSilence() async {
    if (!isAudioSystemEnabled) {
      return;
    }
    if (_audioController.soLoudIsUnreliable) {
      if (_silencePlayingOnAp()) {
        _log.fine('Silence already playing');
        _isUnlockingSilence = false;
        return;
      }
      !_audioController.isAudioOn ? null : _log.fine("playSilence");
      await _playSfxForceAudioPlayers(SfxType.silence);
    }
  }

  /// Stops all currently playing sounds and clears players map.
  Future<void> stopAllSounds() async {
    if (!isAudioSystemEnabled) {
      return;
    }
    if (_apPlayers.containsKey(SfxType.silence)) {
      try {
        await _apPlayers[SfxType.silence]!.stop();
      } catch (_) {}
      _log.fine(
        () => <Object?>[
          'Stop silence as part of all',
          _apPlayers[SfxType.silence]?.state,
        ],
      );
    }
    _apPlayers.clear();
    _isUnlockingSilence = false;
  }
}
