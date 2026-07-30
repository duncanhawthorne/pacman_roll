import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:logging/logging.dart';

import 'audio_controller.dart';
import 'sounds.dart';

/// Manages dynamic volume and state transitions for the ghost roaming siren.
class SirenAudioController {
  SirenAudioController(this._audioController);

  static final Logger _log = Logger('SI');
  final AudioController _audioController;

  /// Dynamically adjusts the volume of the ghost roaming siren.
  ///
  /// IOS GUARD: Called by Flame's periodic timer. Bails out silently if iOS audio is locked
  /// waiting for a tap, preventing the background timer from forcing an invalid SoLoud init.
  Future<void> setVolume(
    double normalisedAverageGhostSpeed, {
    bool gradual = false,
  }) async {
    const SfxType siren = SfxType.ghostsRoamingSiren;

    // GUARD: On iOS Web, if the user hasn't tapped yet after resume,
    // bail out silently so the periodic timer doesn't force a SoLoud init.
    if (!(await _audioController.canPlay(siren))) return;

    double currentVolume = 0;

    if (!_audioController.isPlaying(siren)) {
      _log.info('Restarting ghostsRoamingSiren');
      await _audioController.play(siren);
    }

    final SoundHandle? handle = _audioController.getHandle(siren);
    if (handle == null) return;

    currentVolume = soLoud.getVolume(handle);
    final double desiredSirenVolume = _getDesiredSirenVolume(
      normalisedAverageGhostSpeed,
      currentVolume,
      gradual: gradual,
    );
    soLoud.setVolume(handle, desiredSirenVolume);
  }

  /// Calculates target siren volume from normalized ghost speed.
  double _getUltimateTargetSirenVolume(double normalisedAverageGhostSpeed) {
    final double tmpSirenVolume = normalisedAverageGhostSpeed * 5; //1.25;
    return min(1, tmpSirenVolume) * volumeScalar;
  }

  /// Computes target volume, supporting gradual step interpolation and small-volume zeroing.
  double _getDesiredSirenVolume(
    double normalisedAverageGhostSpeed,
    double currentVolume, {
    bool gradual = false,
  }) {
    double targetVolume = _getUltimateTargetSirenVolume(
      normalisedAverageGhostSpeed,
    );
    if (gradual) {
      targetVolume = (targetVolume + currentVolume) / 2;
    }
    targetVolume = targetVolume < 0.01 * volumeScalar ? 0 : targetVolume;
    return targetVolume;
  }
}
