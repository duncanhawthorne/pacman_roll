import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../audio/audio_controller.dart';

/// This file has utilities used by other bits of code

final Logger _globalLog = Logger('GL');

void logGlobal(dynamic x) {
  _globalLog.info(x);
}

final List<String> debugLogList = <String>[""];
const int debugLogListMaxLength = 30;
final ValueNotifier<int> debugLogListNotifier = ValueNotifier<int>(0);

void setupGlobalLogger() {
  Logger.root.level = (kDebugMode || detailedAudioLog)
      ? Level.FINE
      : Level.INFO;
  //logging.hierarchicalLoggingEnabled = true;
  Logger.root.onRecord.listen((LogRecord record) {
    final String time =
        "${DateTime.now().minute}:${DateTime.now().second}.${DateTime.now().millisecond}";
    final String message = '$time ${record.loggerName} ${record.message}';
    debugPrint(message);
    debugLogList.add(message);
    if (debugLogList.length > debugLogListMaxLength) {
      debugLogList.removeAt(0);
    }
    debugLogListNotifier.value += 1;
  });
}
