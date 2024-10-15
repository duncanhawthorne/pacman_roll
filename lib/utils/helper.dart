import 'dart:core';

import 'package:flutter/material.dart';

/// This file has utilities used by other bits of code

void debug(dynamic x) {
  debugPrint("D ${DateTime.now()} $x");
}
