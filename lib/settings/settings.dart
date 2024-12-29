// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'persistence/local_storage_settings_persistence.dart';
import 'persistence/settings_persistence.dart';

/// An class that holds settings like [playerName] or [defunctMusicOn],
/// and saves them to an injected persistence store.
class SettingsController {
  /// Creates a new instance of [SettingsController] backed by [store].
  ///
  /// By default, settings are persisted using [LocalStorageSettingsPersistence]
  /// (i.e. NSUserDefaults on iOS, SharedPreferences on Android or
  /// local storage on the web).
  SettingsController({SettingsPersistence? store})
      : _store = store ?? LocalStorageSettingsPersistence() {
    _loadStateFromPersistence();
  }

  static final Logger _log = Logger('SC');

  /// The persistence store that is used to save settings.
  final SettingsPersistence _store;

  /// Whether or not the audio is on at all. This overrides both music
  /// and sounds (sfx).
  ///
  /// This is an important feature especially on mobile, where players
  /// expect to be able to quickly mute all the audio. Having this as
  /// a separate flag (as opposed to some kind of {off, sound, everything}
  /// enum) means that the player will not lose their [defunctSoundsOn] and
  /// [defunctMusicOn] preferences when they temporarily mute the game.
  ValueNotifier<bool> audioOn = ValueNotifier<bool>(true);

  /// The player's name. Used for things like high score lists.
  ValueNotifier<String> playerName = ValueNotifier<String>('Player');

  /// Whether or not the sound effects (sfx) are on.
  ValueNotifier<bool> defunctSoundsOn = ValueNotifier<bool>(true);

  /// Whether or not the music is on.
  ValueNotifier<bool> defunctMusicOn = ValueNotifier<bool>(true);

  void setPlayerName(String name) {
    playerName.value = name;
    _store.savePlayerName(playerName.value);
  }

  void toggleAudioOn() {
    audioOn.value = !audioOn.value;
    _store.saveAudioOn(audioOn.value);
  }

  void defunctToggleMusicOn() {
    defunctMusicOn.value = !defunctMusicOn.value;
    _store.saveMusicOn(defunctMusicOn.value);
  }

  void defunctToggleSoundsOn() {
    defunctSoundsOn.value = !defunctSoundsOn.value;
    _store.saveSoundsOn(defunctSoundsOn.value);
  }

  /// Asynchronously loads values from the injected persistence store.
  Future<void> _loadStateFromPersistence() async {
    final List<Object> loadedValues = await Future.wait(<Future<Object>>[
      _store.getAudioOn(defaultValue: false).then((bool value) {
        if (kIsWeb) {
          // On the web, sound can only start after user interaction, so
          // we start muted there on every game start.
          return audioOn.value = value; //false;
        }
        // On other platforms, we can use the persisted value.
        return audioOn.value = value; //true; //value;
      }),
      _store
          .getSoundsOn(defaultValue: true)
          .then((bool value) => defunctSoundsOn.value = true), //value
      _store
          .getMusicOn(defaultValue: true)
          .then((bool value) => defunctMusicOn.value = false), //value
      _store.getPlayerName().then((String value) => playerName.value = value),
    ]);

    _log.fine(() => 'Loaded settings: $loadedValues');
  }
}
