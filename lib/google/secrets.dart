import 'package:flutter/foundation.dart';

// This is a stub file to enable the code to run successfully without a
// proper google secrets file and therefore with google disabled.
// To actually use google, update the secrets below from google
// and set googleOnReal = true;

const bool googleOnReal = false;

final String gID = (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS) &&
        !kIsWeb
    ? 'X'
    : 'X';