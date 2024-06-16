import 'package:firebase_core/firebase_core.dart';

// This is a stub file to enable the code to run successfully without a
// proper firebase_options file and therefore with firebsae disabled.
// To actually use firebase, replace this file with a firebase_options file
// downloaded from flutterfire and add one line to set firebaseOnReal = true;

const firebaseOnReal = false;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'X',
      appId: 'X',
      messagingSenderId: 'X',
      projectId: 'X',
      authDomain: 'X',
      storageBucket: 'X',
    );
  }
}
