import 'dart:ui';

import 'package:flame/components.dart';

import '../components/game_character.dart';

class StubSprites {
  Picture _stubRecorder() {
    final PictureRecorder recorder = PictureRecorder();
    // need to use recorder else throws error
    // ignore: unused_local_variable
    final Canvas canvas = Canvas(recorder);
    return recorder.endRecording();
  }

  late final Sprite _stubSprite = Sprite(_stubRecorder().toImageSync(1, 1));

  Map<CharacterState, SpriteAnimation> _stubAnimations() {
    final Map<CharacterState, SpriteAnimation> result =
        <CharacterState, SpriteAnimation>{};
    for (CharacterState state in CharacterState.values) {
      result[state] = SpriteAnimation.spriteList(
        <Sprite>[_stubSprite],
        stepTime: double.infinity,
      );
    }
    return result;
  }

  late final Map<CharacterState, SpriteAnimation> stubAnimation =
      _stubAnimations();
}

StubSprites stubSprites = StubSprites();
