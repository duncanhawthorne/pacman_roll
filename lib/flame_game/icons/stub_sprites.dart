import 'dart:core';
import 'dart:ui';

import 'package:flame/components.dart';

import '../components/game_character.dart';

class StubSprites {
  Picture _stubRecorder() {
    final recorder = PictureRecorder();
    // need to use recorder else throws error
    // ignore: unused_local_variable
    final canvas = Canvas(recorder);
    Picture picture = recorder.endRecording();
    return picture;
  }

  late final _stubSprite = Sprite(_stubRecorder().toImageSync(1, 1));

  Map<CharacterState, SpriteAnimation> _stubAnimations() {
    Map<CharacterState, SpriteAnimation> result = {};
    for (var x in CharacterState.values) {
      result[x] = SpriteAnimation.spriteList(
        [_stubSprite],
        stepTime: double.infinity,
      );
    }
    return result;
  }

  late final stubAnimation = _stubAnimations();
}

StubSprites stubSprites = StubSprites();
