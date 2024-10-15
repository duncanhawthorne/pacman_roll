import 'dart:core';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

void removeEffects(Component component) {
  component.children.whereType<Effect>().forEach((Effect item) {
    item.pause(); //sync
  });
  component.removeWhere((Component item) => item is Effect); //async
}
