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

  double _getUltimateTargetSirenVolume(double normalisedAverageGhostSpeed) {
    final double tmpSirenVolume = normalisedAverageGhostSpeed / 30 * 2.5;
    return min(1, tmpSirenVolume) * volumeScalar;
  }

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

  /// Dynamically adjusts the volume of the ghost roaming siren.
  Future<void> setVolume(
    double normalisedAverageGhostSpeed, {
    bool gradual = false,
  }) async {
    const SfxType siren = SfxType.ghostsRoamingSiren;
    if (!(await _audioController.canPlay(siren))) {
      return;
    }
    double currentVolume = 0;

    await _audioController.soLoudEnsureInitialised();
    if (!(await _audioController.soLoudHandleValid(siren)) ||
        soLoud.getPause(_audioController.getHandle(siren)!)) {
      _log.info('Restarting ghostsRoamingSiren');
      await _audioController.playSfx(siren);
    }
    final SoundHandle handle = _audioController.getHandle(siren)!;
    currentVolume = soLoud.getVolume(handle);
    final double desiredSirenVolume = _getDesiredSirenVolume(
      normalisedAverageGhostSpeed,
      currentVolume,
      gradual: gradual,
    );
    soLoud.setVolume(handle, desiredSirenVolume);
  }
}
