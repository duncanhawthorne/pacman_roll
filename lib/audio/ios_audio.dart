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

  /// Plays a specific sound effect.
  Future<void> _playSfxForceAudioPlayers(SfxType type) async {
    if (!isAudioSystemEnabled) {
      return;
    }
    !_audioController.isAudioOn ? null : _log.fine('Playing $type');
    if (!(await _audioController.canPlay(type))) {
      return;
    }
    if (_silencePlayingOnAp()) {
      //leave silence repeating
      _log.fine('Silence already playing');
      return;
    }
    if (!_apPlayers.containsKey(type)) {
      _apPlayers[type] = AudioPlayer(playerId: 'sfxPlayer#$type');
    }
    final AudioPlayer currentPlayer = _apPlayers[type]!;
    await currentPlayer.setReleaseMode(ReleaseMode.loop);
    await currentPlayer.play(
      AssetSource(type.filename),
      volume: type.targetVolume,
    );
    await currentPlayer.play(
      AssetSource(type.filename),
      volume: type.targetVolume,
    );
    _log.finest(() => "Player state $type ${currentPlayer.state}");
  }

  /// Safari workaround: triggers audio activation on a user-initiated event.
  Future<void> workaround() async {
    //ideally replaced by ensureSilencePlaying
    //FIXME requires testing
    await _playSilence();
  }

  /// Returns true if the silent track is currently playing via AudioPlayers.
  bool _silencePlayingOnAp() {
    final SfxType type = SfxType.silence;
    return _apPlayers.containsKey(type) &&
        _apPlayers[type]!.state == PlayerState.playing;
  }

  /// Plays a silent track to keep the audio session active.
  Future<void> _playSilence() async {
    if (!isAudioSystemEnabled) {
      return;
    }
    //holds open sound channel where soLoud is unreliable
    if (_audioController.soLoudIsUnreliable) {
      !_audioController.isAudioOn ? null : _log.fine("playSilence");
      await _playSfxForceAudioPlayers(SfxType.silence);
    }
  }

  /// Stops all currently playing sounds.
  Future<void> stopAllSounds() async {
    if (!isAudioSystemEnabled) {
      return;
    }
    if (_apPlayers.containsKey(SfxType.silence)) {
      await _apPlayers[SfxType.silence]!.stop();
      _log.fine(
        () => <Object?>[
          'Stop silence as part of all',
          _apPlayers[SfxType.silence]?.state,
        ],
      );
    }
  }
}
