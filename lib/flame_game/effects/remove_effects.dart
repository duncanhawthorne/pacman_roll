import 'dart:core';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

void removeEffects(Component component) {
  component.children
      .whereType<Effect>()
      //create a new list toList so can iterate and remove simultaneously
      .toList(growable: false)
      .forEach((Effect item) {
        item
          ..pause() //sync
          ..removeFromParent();
      });
}
